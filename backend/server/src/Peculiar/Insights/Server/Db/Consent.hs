module Peculiar.Insights.Server.Db.Consent
  ( consentOf
  , eraseOf
  ) where

import Data.Foldable (for_)
import Data.Int (Int32, Int64)
import Data.Maybe (isJust)
import Data.Text qualified as T
import Data.Time (UTCTime)
import Database.Beam
import Database.Beam.Backend.SQL.Types (SqlSerial (..))
import Database.Beam.Postgres (Pg, Postgres)
import Peculiar.Insights.Core.Consent (ConsentState (..), PolicyVersion (..), PurposeState (..), purposeName)
import Peculiar.Insights.Server.Db.Publish (claim)
import Peculiar.Insights.Server.Db.Subject (touchDevice)
import Peculiar.Insights.Server.Db.Types
import Peculiar.Insights.Server.Schema qualified as S

consentOf :: Int32 -> UTCTime -> ConsentRecord -> Pg Stored
consentOf projectId now record = do
  fresh <- claim projectId now record.id
  if not fresh
    then pure (Duplicate record.id)
    else do
      device <- touchDevice projectId record.time record.device
      let PolicyVersion policy = record.state.policyVersion
      runInsert
        ( insert
            db.consent
            ( insertValues
                [ S.Consent
                    { projectId
                    , id = uuidOf record.id
                    , deviceId = deviceText record.device
                    , personId = device.personId
                    , purpose = purposeName record.purpose
                    , state = case record.state.state of
                        Granted -> "granted"
                        Withdrawn -> "withdrawn"
                    , policyVersion = policy
                    , time = record.time
                    , receivedAt = now
                    }
                ]
            )
        )
      pure (Stored record.id)

data Scope = Scope
  { projectId :: Int32
  , deviceId :: T.Text
  , linked :: Maybe Int64
  }

belongs :: Scope -> (QExpr Postgres s Int32, QExpr Postgres s T.Text, QExpr Postgres s (Maybe Int64)) -> QExpr Postgres s Bool
belongs scope (rowProject, rowDevice, rowPerson) =
  (rowProject ==. val_ scope.projectId &&. rowDevice ==. val_ scope.deviceId)
    ||. (rowProject ==. val_ scope.projectId &&. rowPerson ==. val_ scope.linked &&. val_ (isJust scope.linked))

eraseOf :: Int32 -> UTCTime -> ErasureRequest -> Pg Erased
eraseOf projectId now request = do
  fresh <- claim projectId now request.id
  if not fresh
    then pure ErasureDuplicate
    else do
      let deviceId = deviceText request.device
      device <- runSelectReturningOne (lookup_ db.device (S.DeviceKey projectId deviceId))
      person <- case request.user of
        Nothing -> pure Nothing
        Just user ->
          runSelectReturningOne (select (filter_ (\row -> row.projectId ==. val_ projectId &&. row.userId ==. val_ (userText user)) (all_ db.person)))
      let linked = case (device, person) of
            (Just d, Just p) | d.personId == Just (unSerial p.id) -> Just (unSerial p.id)
            _ -> Nothing
          scope = Scope{projectId, deviceId, linked}
      runDelete (delete db.event (\row -> belongs scope (row.projectId, row.deviceId, row.personId)))
      runDelete (delete db.crash (\row -> belongs scope (row.projectId, row.deviceId, row.personId)))
      runDelete (delete db.session (\row -> belongs scope (row.projectId, row.deviceId, row.personId)))
      runDelete (delete db.consent (\row -> belongs scope (row.projectId, row.deviceId, row.personId)))
      for_ linked \personId -> do
        runUpdate (update db.device (\row -> row.personId <-. val_ Nothing) (\row -> row.projectId ==. val_ projectId &&. row.personId ==. val_ (Just personId)))
        runDelete (delete db.person (\row -> row.id ==. val_ (SqlSerial personId)))
      runDelete (delete db.device (\row -> row.projectId ==. val_ projectId &&. row.id ==. val_ deviceId))
      runInsert
        ( insert
            db.erasure
            ( insertValues
                [ S.Erasure
                    { projectId
                    , id = uuidOf request.id
                    , deviceId
                    , personId = linked
                    , requestedAt = request.time
                    , completedAt = now
                    }
                ]
            )
        )
      pure Erased
