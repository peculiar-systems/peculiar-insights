module Peculiar.Insights.Server.Db.Subject
  ( touchDevice
  , ensurePerson
  , link
  , Visit (..)
  , touchSession
  , resolveSubject
  ) where

import Control.Applicative ((<|>))
import Control.Monad (unless)
import Data.Aeson qualified as Aeson
import Data.Int (Int32, Int64)
import Data.Time (UTCTime)
import Database.Beam
import Database.Beam.Backend.SQL.BeamExtensions (runInsertReturningList)
import Database.Beam.Backend.SQL.Types (SqlSerial (..))
import Database.Beam.Postgres (Pg, PgJSONB (..))
import Peculiar.Insights.Core.Item (Context (..), DeviceId (..), Subject (..), UserId (..))
import Peculiar.Insights.Server.Db.Types (db, deviceText, platformText, sessionText, single)
import Peculiar.Insights.Server.Schema qualified as S

touchDevice :: Int32 -> UTCTime -> DeviceId -> Pg (S.DeviceT Identity)
touchDevice projectId at (DeviceId deviceId) = do
  existing <- runSelectReturningOne (lookup_ db.device (S.DeviceKey projectId deviceId))
  case existing of
    Just device -> do
      runUpdate
        ( update
            db.device
            (\row -> mconcat [row.lastSeen <-. val_ (max at device.lastSeen), row.firstSeen <-. val_ (min at device.firstSeen)])
            (\row -> row.projectId ==. val_ projectId &&. row.id ==. val_ deviceId)
        )
      pure device
    Nothing -> do
      let device = S.Device{projectId, id = deviceId, personId = Nothing, firstSeen = at, lastSeen = at}
      runInsert (insert db.device (insertValues [device]))
      pure device

ensurePerson :: Int32 -> UTCTime -> UserId -> Pg (S.PersonT Identity)
ensurePerson projectId at (UserId userId) = do
  existing <- runSelectReturningOne (select (filter_ (\row -> row.projectId ==. val_ projectId &&. row.userId ==. val_ userId) (all_ db.person)))
  case existing of
    Just person -> do
      runUpdate
        ( update
            db.person
            (\row -> mconcat [row.lastSeen <-. val_ (max at person.lastSeen), row.firstSeen <-. val_ (min at person.firstSeen)])
            (\row -> row.id ==. val_ person.id)
        )
      pure person
    Nothing ->
      runInsertReturningList
        ( insert
            db.person
            ( insertExpressions
                [ S.Person
                    { id = default_
                    , projectId = val_ projectId
                    , userId = val_ userId
                    , properties = val_ (PgJSONB (Aeson.object []))
                    , firstSeen = val_ at
                    , lastSeen = val_ at
                    }
                ]
            )
        )
        >>= single "inserting a person"

link :: Int32 -> DeviceId -> S.PersonT Identity -> Pg ()
link projectId (DeviceId deviceId) person = do
  device <- runSelectReturningOne (lookup_ db.device (S.DeviceKey projectId deviceId))
  let personId = unSerial person.id
  unless (fmap (.personId) device == Just (Just personId)) do
    runUpdate
      ( update
          db.device
          (\row -> row.personId <-. val_ (Just personId))
          (\row -> row.projectId ==. val_ projectId &&. row.id ==. val_ deviceId)
      )
    runUpdate
      ( update
          db.event
          (\row -> row.personId <-. val_ (Just personId))
          (\row -> row.projectId ==. val_ projectId &&. row.deviceId ==. val_ deviceId &&. isNothing_ row.personId)
      )
    runUpdate
      ( update
          db.crash
          (\row -> row.personId <-. val_ (Just personId))
          (\row -> row.projectId ==. val_ projectId &&. row.deviceId ==. val_ deviceId &&. isNothing_ row.personId)
      )
    runUpdate
      ( update
          db.session
          (\row -> row.personId <-. val_ (Just personId))
          (\row -> row.projectId ==. val_ projectId &&. row.deviceId ==. val_ deviceId &&. isNothing_ row.personId)
      )

data Visit = Visit
  { subject :: Subject
  , personId :: Maybe Int64
  , at :: UTCTime
  , context :: Context
  , crashed :: Bool
  }

touchSession :: Int32 -> Visit -> Pg ()
touchSession projectId visit = do
  let sessionId = sessionText visit.subject.session
  existing <- runSelectReturningOne (lookup_ db.session (S.SessionKey projectId sessionId))
  case existing of
    Just session ->
      runUpdate
        ( update
            db.session
            ( \row ->
                mconcat
                  [ row.startedAt <-. val_ (min visit.at session.startedAt)
                  , row.lastSeenAt <-. val_ (max visit.at session.lastSeenAt)
                  , row.crashed <-. val_ (session.crashed || visit.crashed)
                  , row.personId <-. val_ (session.personId <|> visit.personId)
                  ]
            )
            (\row -> row.projectId ==. val_ projectId &&. row.id ==. val_ sessionId)
        )
    Nothing ->
      runInsert
        ( insert
            db.session
            ( insertValues
                [ S.Session
                    { projectId
                    , id = sessionId
                    , deviceId = deviceText visit.subject.device
                    , personId = visit.personId
                    , startedAt = visit.at
                    , lastSeenAt = visit.at
                    , crashed = visit.crashed
                    , appVersion = visit.context.appVersion
                    , platform = platformText visit.context.platform
                    }
                ]
            )
        )

resolveSubject :: Int32 -> UTCTime -> Subject -> Pg (Maybe Int64)
resolveSubject projectId at subject = do
  device <- touchDevice projectId at subject.device
  case subject.user of
    Nothing -> pure device.personId
    Just user -> do
      person <- ensurePerson projectId at user
      link projectId subject.device person
      pure (Just (unSerial person.id))
