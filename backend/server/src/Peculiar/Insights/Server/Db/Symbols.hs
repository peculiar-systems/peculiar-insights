module Peculiar.Insights.Server.Db.Symbols
  ( StoredKind (..)
  , BuildCrash (..)
  , Regrouped (..)
  , KeptBuild (..)
  , entriesOf
  , openBuild
  , replaceKinds
  , crashesOf
  , regroupAll
  , keptBuilds
  , dropBuilds
  , markReported
  ) where

import Control.Monad (unless, when)
import Data.Aeson qualified as Aeson
import Data.Foldable (for_)
import Data.Int (Int32, Int64)
import Data.List.NonEmpty (NonEmpty (..))
import Data.List.NonEmpty qualified as NonEmpty
import Data.Map.Strict qualified as Map
import Data.Maybe (fromMaybe, mapMaybe)
import Data.Set qualified as Set
import Data.Text qualified as T
import Data.Time (UTCTime)
import Data.Traversable (for)
import Data.UUID.Types (UUID)
import Database.Beam
import Database.Beam.Backend.SQL.BeamExtensions (runInsertReturningList)
import Database.Beam.Backend.SQL.Types (SqlSerial (..))
import Database.Beam.Postgres (Pg, PgJSONB (..))
import Database.Beam.Postgres.Full (conflictingFields, insertReturning, onConflict, onConflictUpdateSet, runPgInsertReturningList)
import Peculiar.Insights.Core.Issue (IssueState (..), stateFromName, stateName)
import Peculiar.Insights.Core.Item (Frame, Platform)
import Peculiar.Insights.Core.Symbols (Entry (..), SymbolKind, inheritedState, kindFromName, kindName)
import Peculiar.Insights.Server.Db.Types (db, platformFromText, single)
import Peculiar.Insights.Server.Schema qualified as S

data StoredKind = StoredKind
  { kind :: SymbolKind
  , directory :: FilePath
  , files :: Int
  , entries :: [Entry]
  }
  deriving stock (Eq, Show)

data BuildCrash = BuildCrash
  { projectId :: Int32
  , id :: UUID
  , issueId :: Int64
  , time :: UTCTime
  , build :: T.Text
  , platform :: Platform
  , exceptionType :: T.Text
  , message :: T.Text
  , rawFrames :: [Frame]
  }
  deriving stock (Eq, Show)

data Regrouped = Regrouped
  { crash :: BuildCrash
  , frames :: [Frame]
  , fingerprint :: T.Text
  , title :: T.Text
  }
  deriving stock (Eq, Show)

data KeptBuild = KeptBuild
  { id :: Int32
  , project :: T.Text
  , uploadedAt :: UTCTime
  , reported :: Bool
  , hasReports :: Bool
  }
  deriving stock (Eq, Show)

entriesOf :: T.Text -> T.Text -> Pg [Entry]
entriesOf project build = do
  built <- runSelectReturningList (select (filter_ (\row -> row.project ==. val_ project &&. row.build ==. val_ build) (all_ db.symbolBuild)))
  let ids = fmap (unSerial . (.id)) built
  rows <- if null ids then pure [] else runSelectReturningList (select (filter_ (\entry -> entry.buildId `in_` fmap val_ ids) (all_ db.symbolEntry)))
  pure (mapMaybe entryOf rows)
 where
  entryOf row = (\kind -> Entry{kind, identifier = row.identifier, path = T.unpack row.path}) <$> kindFromName row.kind

projectIds :: T.Text -> Pg [Int32]
projectIds project = fmap (unSerial . (.id)) <$> runSelectReturningList (select (filter_ (\row -> row.slug ==. val_ project) (all_ db.project)))

openBuild :: T.Text -> T.Text -> UTCTime -> Pg Int32
openBuild project build now =
  runPgInsertReturningList
    ( insertReturning
        db.symbolBuild
        (insertExpressions [S.SymbolBuild{id = default_, project = val_ project, build = val_ build, uploadedAt = val_ now, reported = val_ False}])
        (onConflict (conflictingFields (\row -> (row.project, row.build))) (onConflictUpdateSet (\row _ -> row.uploadedAt <-. val_ now)))
        (Just (\row -> row.id))
    )
    >>= fmap unSerial . single "opening a symbol build"

replaceKinds :: Int32 -> T.Text -> T.Text -> [StoredKind] -> Pg [FilePath]
replaceKinds buildId project build stored = do
  let names = fmap (kindName . (.kind)) stored
  previous <- runSelectReturningList (select (filter_ (\row -> row.buildId ==. val_ buildId &&. row.kind `in_` fmap val_ names) (all_ db.symbolKind)))
  runDelete (delete db.symbolKind (\row -> row.buildId ==. val_ buildId &&. row.kind `in_` fmap val_ names))
  unless (null stored) do
    runInsert (insert db.symbolKind (insertValues [S.SymbolKind{buildId, kind = kindName kind.kind, directory = T.pack kind.directory, files = fromIntegral kind.files} | kind <- stored]))
    let unique = Map.elems (Map.fromList [((kindName entry.kind, entry.identifier), entry) | kind <- stored, entry <- kind.entries])
    unless (null unique) do
      runInsert (insert db.symbolEntry (insertValues [S.SymbolEntry{buildId, kind = kindName entry.kind, identifier = entry.identifier, path = T.pack entry.path} | entry <- unique]))
  reported <- hasCrashes project build
  when reported do
    runUpdate (update db.symbolBuild (\row -> row.reported <-. val_ True) (\row -> row.id ==. val_ (SqlSerial buildId)))
  pure (fmap (T.unpack . (.directory)) previous)

hasCrashes :: T.Text -> T.Text -> Pg Bool
hasCrashes project build = do
  ids <- projectIds project
  found <- if null ids then pure [] else runSelectReturningList (select (limit_ 1 (fmap (.id) (filter_ (\row -> row.projectId `in_` fmap val_ ids &&. row.appBuild ==. val_ build) (all_ db.crash)))))
  pure (not (null found))

markReported :: T.Text -> T.Text -> Pg ()
markReported project build =
  runUpdate (update db.symbolBuild (\row -> row.reported <-. val_ True) (\row -> row.project ==. val_ project &&. row.build ==. val_ build &&. not_ row.reported))

crashesOf :: T.Text -> T.Text -> Pg [BuildCrash]
crashesOf project build = do
  ids <- projectIds project
  rows <- if null ids then pure [] else runSelectReturningList (select (filter_ (\row -> row.projectId `in_` fmap val_ ids &&. row.appBuild ==. val_ build) (all_ db.crash)))
  pure (fmap crashOf rows)
 where
  crashOf row =
    let PgJSONB raw = row.rawFrames
     in BuildCrash
          { projectId = row.projectId
          , id = row.id
          , issueId = row.issueId
          , time = row.time
          , build = row.appBuild
          , platform = platformFromText row.platform
          , exceptionType = row.exceptionType
          , message = row.message
          , rawFrames = case Aeson.fromJSON raw of
              Aeson.Success frames -> frames
              Aeson.Error _ -> []
          }

regroupAll :: [Regrouped] -> Pg ()
regroupAll regrouped = do
  for_ regrouped \moved ->
    runUpdate
      ( update
          db.crash
          (\row -> row.frames <-. val_ (PgJSONB (Aeson.toJSON moved.frames)))
          (\row -> row.projectId ==. val_ moved.crash.projectId &&. row.id ==. val_ moved.crash.id)
      )
  let sources = Set.toList (Set.fromList (fmap (.crash.issueId) regrouped))
  issues <- runSelectReturningList (select (filter_ (\row -> row.id `in_` fmap (val_ . SqlSerial) sources) (all_ db.issue)))
  let byId = Map.fromList [(unSerial issue.id, issue) | issue <- issues]
      moving = [moved | moved <- regrouped, fmap (.fingerprint) (Map.lookup moved.crash.issueId byId) /= Just moved.fingerprint]
      targets = Map.fromListWith (flip (<>)) [((moved.crash.projectId, moved.fingerprint), moved :| []) | moved <- moving]
  for_ (Map.toList targets) \((projectId, printed), group) -> do
    existing <- runSelectReturningOne (select (filter_ (\row -> row.projectId ==. val_ projectId &&. row.fingerprint ==. val_ printed) (all_ db.issue)))
    target <- case existing of
      Just row -> unSerial row.id <$ widen row group
      Nothing -> created projectId printed [issue | moved <- NonEmpty.toList group, Just issue <- [Map.lookup moved.crash.issueId byId]] group
    for_ group \moved ->
      runUpdate
        ( update
            db.crash
            (\row -> row.issueId <-. val_ target)
            (\row -> row.projectId ==. val_ moved.crash.projectId &&. row.id ==. val_ moved.crash.id)
        )
  for_ sources \issueId -> do
    remaining <- runSelectReturningList (select (limit_ 1 (filter_ (\row -> row.issueId ==. val_ issueId) (all_ db.crash))))
    when (null remaining) do
      runDelete (delete db.issue (\row -> row.id ==. val_ (SqlSerial issueId)))

widen :: S.IssueT Identity -> NonEmpty Regrouped -> Pg ()
widen row group =
  runUpdate
    ( update
        db.issue
        ( \issue ->
            mconcat
              [ issue.firstSeen <-. val_ (minimum' row.firstSeen (fmap (.crash.time) group))
              , issue.lastSeen <-. val_ (maximum' row.lastSeen (fmap (.crash.time) group))
              , issue.firstBuild <-. val_ (minimum' row.firstBuild (fmap (.crash.build) group))
              , issue.lastBuild <-. val_ (maximum' row.lastBuild (fmap (.crash.build) group))
              ]
        )
        (\issue -> issue.id ==. val_ row.id)
    )

created :: Int32 -> T.Text -> [S.IssueT Identity] -> NonEmpty Regrouped -> Pg Int64
created projectId printed left group = do
  let first :| _ = NonEmpty.sortWith (.crash.time) group
      state = inheritedState [fromMaybe Open (stateFromName issue.state) | issue <- left]
      resolved = state == Resolved
      times = fmap (.crash.time) group
      builds = fmap (.crash.build) group
  inserted <-
    runInsertReturningList
      ( insert
          db.issue
          ( insertExpressions
              [ S.Issue
                  { id = default_
                  , projectId = val_ projectId
                  , fingerprint = val_ printed
                  , title = val_ first.title
                  , exceptionType = val_ first.crash.exceptionType
                  , state = val_ (stateName state)
                  , firstSeen = val_ (minimum' first.crash.time times)
                  , lastSeen = val_ (maximum' first.crash.time times)
                  , firstBuild = val_ (minimum' first.crash.build builds)
                  , lastBuild = val_ (maximum' first.crash.build builds)
                  , resolvedAt = val_ (if resolved then latest (fmap (.resolvedAt) left) else Nothing)
                  , resolvedBuild = val_ (if resolved then latest (fmap (.resolvedBuild) left) else Nothing)
                  , regressedAt = val_ Nothing
                  , regrouped = val_ True
                  }
              ]
          )
      )
      >>= single "creating a regrouped issue"
  pure (unSerial inserted.id)

latest :: (Ord a) => [Maybe a] -> Maybe a
latest = foldr max Nothing

minimum' :: (Foldable t, Ord a) => a -> t a -> a
minimum' = foldr min

maximum' :: (Foldable t, Ord a) => a -> t a -> a
maximum' = foldr max

keptBuilds :: Pg [KeptBuild]
keptBuilds = do
  builds <- runSelectReturningList (select (all_ db.symbolBuild))
  for builds \row -> do
    reports <- hasCrashes row.project row.build
    pure KeptBuild{id = unSerial row.id, project = row.project, uploadedAt = row.uploadedAt, reported = row.reported, hasReports = reports}

dropBuilds :: [Int32] -> Pg [FilePath]
dropBuilds [] = pure []
dropBuilds ids = do
  kinds <- runSelectReturningList (select (filter_ (\row -> row.buildId `in_` fmap val_ ids) (all_ db.symbolKind)))
  runDelete (delete db.symbolBuild (\row -> row.id `in_` fmap (val_ . SqlSerial) ids))
  pure (fmap (T.unpack . (.directory)) kinds)
