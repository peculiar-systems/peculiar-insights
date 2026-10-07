module Peculiar.Insights.Server.Db.Publish
  ( publishAll
  , claim
  ) where

import Control.Monad (void, when)
import Data.Aeson qualified as Aeson
import Data.Aeson.KeyMap qualified as KeyMap
import Data.Foldable (for_)
import Data.Int (Int32, Int64)
import Data.Map.Strict qualified as Map
import Data.Maybe (fromMaybe)
import Data.Set qualified as Set
import Data.Time (UTCTime)
import Database.Beam
import Database.Beam.Backend.SQL.BeamExtensions (runInsertReturningList)
import Database.Beam.Backend.SQL.Types (SqlSerial (..))
import Database.Beam.Postgres (Pg, PgJSONB (..))
import Database.Beam.Postgres.Full (anyConflict, insertReturning, onConflict, onConflictDoNothing, runPgInsertReturningList)
import Peculiar.Insights.Core.Config (Project (..))
import Peculiar.Insights.Core.Fingerprint (Fingerprint (..), fingerprint, title)
import Peculiar.Insights.Core.Issue qualified as Issue
import Peculiar.Insights.Core.Item
import Peculiar.Insights.Core.Profile qualified as Profile
import Peculiar.Insights.Core.Value (toAeson)
import Peculiar.Insights.Server.Db.Subject (Visit (..), ensurePerson, link, resolveSubject, touchDevice, touchSession)
import Peculiar.Insights.Server.Db.Symbols (markReported)
import Peculiar.Insights.Server.Db.Types (Stored (..), db, deviceText, platformText, sessionText, single, uuidOf)
import Peculiar.Insights.Server.Projects (Registered (..))
import Peculiar.Insights.Server.Schema qualified as S

publishAll :: Registered -> UTCTime -> [Item] -> Map.Map ItemId [Frame] -> Pg [Stored]
publishAll registered now items symbolicated = do
  let projectId = registered.id
  let unique = dedupe items
  fresh <-
    if null unique
      then pure []
      else
        runPgInsertReturningList
          ( insertReturning
              db.ingested
              (insertValues [S.Ingested{projectId, id = uuidOf (itemId item), receivedAt = now} | item <- unique])
              (onConflict anyConflict onConflictDoNothing)
              (Just (.id))
          )
  let accepted = Set.fromList fresh
  for_ unique \item -> when (Set.member (uuidOf (itemId item)) accepted) (store registered now symbolicated item)
  pure [if Set.member (uuidOf (itemId item)) accepted then Stored (itemId item) else Duplicate (itemId item) | item <- items]

claim :: Int32 -> UTCTime -> ItemId -> Pg Bool
claim projectId now key = do
  fresh <-
    runPgInsertReturningList
      ( insertReturning
          db.ingested
          (insertValues [S.Ingested{projectId, id = uuidOf key, receivedAt = now}])
          (onConflict anyConflict onConflictDoNothing)
          (Just (.id))
      )
  pure (not (null fresh))

dedupe :: [Item] -> [Item]
dedupe = go Set.empty
 where
  go _ [] = []
  go seen (item : rest)
    | Set.member (itemId item) seen = go seen rest
    | otherwise = item : go (Set.insert (itemId item) seen) rest

store :: Registered -> UTCTime -> Map.Map ItemId [Frame] -> Item -> Pg ()
store registered now symbolicated = \case
  ItemEvent event -> storeEvent projectId now event
  ItemIdentify identify -> do
    person <- ensurePerson projectId identify.time identify.user
    void (touchDevice projectId identify.time identify.device)
    link projectId identify.device person
  ItemProfileUpdate profile -> storeProfile projectId profile
  ItemCrashReport crash -> do
    storeCrash projectId now (Map.findWithDefault crash.frames crash.id symbolicated) crash
    markReported registered.project.slug crash.context.appBuild
 where
  projectId = registered.id

storeEvent :: Int32 -> UTCTime -> Event -> Pg ()
storeEvent projectId now event = do
  personId <- resolveSubject projectId event.time event.subject
  runInsert
    ( insert
        db.event
        ( insertValues
            [ S.Event
                { projectId
                , id = uuidOf event.id
                , time = event.time
                , clientTime = event.time
                , receivedAt = now
                , deviceId = deviceText event.subject.device
                , personId
                , sessionId = sessionText event.subject.session
                , name = event.name
                , properties = PgJSONB (Aeson.toJSON (fmap toAeson event.properties))
                , context = PgJSONB (Aeson.toJSON event.context)
                , appVersion = event.context.appVersion
                , appBuild = event.context.appBuild
                , platform = platformText event.context.platform
                }
            ]
        )
    )
  touchSession projectId Visit{subject = event.subject, personId, at = event.time, context = event.context, crashed = False}

storeProfile :: Int32 -> ProfileUpdate -> Pg ()
storeProfile projectId profile = do
  person <- ensurePerson projectId profile.time profile.user
  void (touchDevice projectId profile.time profile.device)
  link projectId profile.device person
  let PgJSONB current = person.properties
      existing = case current of
        Aeson.Object object -> KeyMap.toMapText object
        _ -> Map.empty
      next = Profile.apply existing profile.operations
  runUpdate
    ( update
        db.person
        (\row -> row.properties <-. val_ (PgJSONB (Aeson.toJSON next)))
        (\row -> row.id ==. val_ person.id)
    )

storeCrash :: Int32 -> UTCTime -> [Frame] -> CrashReport -> Pg ()
storeCrash projectId now frames crash = do
  personId <- resolveSubject projectId crash.time crash.subject
  issueId <- ensureIssue projectId frames crash
  runInsert
    ( insert
        db.crash
        ( insertValues
            [ S.Crash
                { projectId
                , id = uuidOf crash.id
                , issueId
                , time = crash.time
                , clientTime = crash.time
                , receivedAt = now
                , deviceId = deviceText crash.subject.device
                , personId
                , sessionId = sessionText crash.subject.session
                , exceptionType = crash.exceptionType
                , message = crash.message
                , frames = PgJSONB (Aeson.toJSON frames)
                , rawStackTrace = crash.rawStackTrace
                , fatal = crash.fatal
                , thread = crash.thread
                , customKeys = PgJSONB (Aeson.toJSON (fmap toAeson crash.customKeys))
                , logs = PgJSONB (Aeson.toJSON crash.logs)
                , context = PgJSONB (Aeson.toJSON crash.context)
                , appVersion = crash.context.appVersion
                , appBuild = crash.context.appBuild
                , platform = platformText crash.context.platform
                , rawFrames = PgJSONB (Aeson.toJSON crash.frames)
                }
            ]
        )
    )
  touchSession projectId Visit{subject = crash.subject, personId, at = crash.time, context = crash.context, crashed = crash.fatal}

ensureIssue :: Int32 -> [Frame] -> CrashReport -> Pg Int64
ensureIssue projectId frames crash = do
  let Fingerprint printed = fingerprint crash.exceptionType crash.message frames
      sighting = Issue.Sighting{at = crash.time, build = crash.context.appBuild}
  existing <- runSelectReturningOne (select (filter_ (\row -> row.projectId ==. val_ projectId &&. row.fingerprint ==. val_ printed) (all_ db.issue)))
  case existing of
    Just row -> do
      let observed = Issue.observe sighting (issueOf row)
      runUpdate
        ( update
            db.issue
            ( \issue ->
                mconcat
                  [ issue.state <-. val_ (Issue.stateName observed.state)
                  , issue.lastSeen <-. val_ observed.lastSeen
                  , issue.lastBuild <-. val_ observed.lastBuild
                  , issue.regressedAt <-. val_ observed.regressedAt
                  ]
            )
            (\issue -> issue.id ==. val_ row.id)
        )
      pure (unSerial row.id)
    Nothing -> do
      inserted <-
        runInsertReturningList
          ( insert
              db.issue
              ( insertExpressions
                  [ S.Issue
                      { id = default_
                      , projectId = val_ projectId
                      , fingerprint = val_ printed
                      , title = val_ (title crash.exceptionType crash.message frames)
                      , exceptionType = val_ crash.exceptionType
                      , state = val_ (Issue.stateName Issue.Open)
                      , firstSeen = val_ crash.time
                      , lastSeen = val_ crash.time
                      , firstBuild = val_ crash.context.appBuild
                      , lastBuild = val_ crash.context.appBuild
                      , resolvedAt = val_ Nothing
                      , resolvedBuild = val_ Nothing
                      , regressedAt = val_ Nothing
                      , regrouped = val_ False
                      }
                  ]
              )
          )
          >>= single "inserting an issue"
      pure (unSerial inserted.id)

issueOf :: S.IssueT Identity -> Issue.Issue
issueOf row =
  Issue.Issue
    { state = fromMaybe Issue.Open (Issue.stateFromName row.state)
    , firstSeen = row.firstSeen
    , lastSeen = row.lastSeen
    , firstBuild = row.firstBuild
    , lastBuild = row.lastBuild
    , resolvedBuild = row.resolvedBuild
    , regressedAt = row.regressedAt
    }
