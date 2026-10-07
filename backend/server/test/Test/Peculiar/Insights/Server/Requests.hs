module Test.Peculiar.Insights.Server.Requests
  ( granted
  , sampleEvent
  , request
  ) where

import Data.ProtoLens (defMessage)
import Data.ProtoLens.Labels ()
import Data.Text qualified as T
import Data.Time (getCurrentTime)
import Data.Time.Clock.POSIX (utcTimeToPOSIXSeconds)
import Lens.Family2 ((&), (.~))
import Proto.Peculiar.Insights.V1.Common
import Proto.Peculiar.Insights.V1.Ingest
import Proto.Peculiar.Insights.V1.Options

granted :: ConsentSnapshot
granted =
  defMessage
    & #purposes
      .~ [ defMessage & #purpose .~ PURPOSE_ANALYTICS & #state .~ CONSENT_STATE_GRANTED & #policyVersion .~ "v1"
         , defMessage & #purpose .~ PURPOSE_DIAGNOSTICS & #state .~ CONSENT_STATE_GRANTED & #policyVersion .~ "v1"
         ]

sampleEvent :: T.Text -> IO Item
sampleEvent identifier = do
  now <- getCurrentTime
  let stamp = defMessage & #seconds .~ floor (utcTimeToPOSIXSeconds now)
      subject = defMessage & #deviceId .~ "api-device" & #sessionId .~ "api-session"
      context = defMessage & #sdkName .~ "test" & #appBuild .~ "1" & #platform .~ PLATFORM_WEB
      event = defMessage & #id .~ identifier & #time .~ stamp & #subject .~ subject & #context .~ context & #name .~ "open"
  pure (defMessage & #event .~ event)

request :: ConsentSnapshot -> [Item] -> IO PublishRequest
request consent items = do
  now <- getCurrentTime
  let stamp = defMessage & #seconds .~ floor (utcTimeToPOSIXSeconds now)
  pure (defMessage & #sentAt .~ stamp & #consent .~ consent & #items .~ items)
