module Peculiar.Insights.Sdk.Direct
  ( SdkError (..)
  , recordConsent
  , requestErasure
  ) where

import Control.Exception (try)
import Data.ProtoLens (defMessage)
import Data.ProtoLens.Labels ()
import Data.Text qualified as T
import Data.Time (getCurrentTime)
import Data.UUID qualified as UUID
import Data.UUID.V4 (nextRandom)
import Lens.Family2 ((&), (.~))
import Peculiar.Insights.Sdk.Client (IngestClient (..))
import Peculiar.Insights.Sdk.Encode (timestamp)
import Peculiar.Insights.Sdk.Types (DeviceId (..), Grant (..), Purpose (..), UserId (..))
import Peculiar.Rpc qualified as Rpc
import Proto.Peculiar.Insights.V1.Common qualified as P
import Proto.Peculiar.Insights.V1.Options qualified as P

newtype SdkError = SdkError T.Text
  deriving stock (Eq, Show)

recordConsent :: IngestClient -> DeviceId -> Maybe UserId -> Purpose -> Grant -> IO (Either SdkError ())
recordConsent remote (DeviceId device) user purpose grant = do
  now <- getCurrentTime
  identifier <- nextRandom
  let state = case grant of
        Granted version -> defMessage & #state .~ P.CONSENT_STATE_GRANTED & #policyVersion .~ version
        Withdrawn version -> defMessage & #state .~ P.CONSENT_STATE_WITHDRAWN & #policyVersion .~ version
      request =
        defMessage
          & #id .~ UUID.toText identifier
          & #time .~ timestamp now
          & #deviceId .~ device
          & #maybe'userId .~ fmap (\(UserId text) -> text) user
          & #purpose .~ (state & #purpose .~ (case purpose of Analytics -> P.PURPOSE_ANALYTICS; Diagnostics -> P.PURPOSE_DIAGNOSTICS))
  outcome <- try @Rpc.RpcError (remote.recordConsent request)
  pure (either (Left . SdkError . (.status.message)) (const (Right ())) outcome)

requestErasure :: IngestClient -> DeviceId -> Maybe UserId -> IO (Either SdkError ())
requestErasure remote (DeviceId device) user = do
  now <- getCurrentTime
  identifier <- nextRandom
  let request = defMessage & #id .~ UUID.toText identifier & #time .~ timestamp now & #deviceId .~ device & #maybe'userId .~ fmap (\(UserId text) -> text) user
  outcome <- try @Rpc.RpcError (remote.requestErasure request)
  pure (either (Left . SdkError . (.status.message)) (const (Right ())) outcome)
