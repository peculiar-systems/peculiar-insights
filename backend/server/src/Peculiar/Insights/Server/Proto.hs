module Peculiar.Insights.Server.Proto
  ( fromItem
  , snapshotOf
  , timeOf
  , consentOf
  , erasureOf
  , itemOutcome
  ) where

import Data.Map.Strict qualified as Map
import Data.Maybe (mapMaybe)
import Data.ProtoLens (defMessage)
import Data.ProtoLens.Labels ()
import Data.Text qualified as T
import Data.Time (UTCTime)
import Data.Time.Clock.POSIX (posixSecondsToUTCTime)
import Data.UUID.Types qualified as UUID
import Lens.Family2 ((&), (.~), (^.))
import Peculiar.Insights.Core.Consent
import Peculiar.Insights.Core.Item
import Peculiar.Insights.Core.Value (Value (..))
import Peculiar.Insights.Server.Db (ConsentRecord (..), ErasureRequest (..))
import Proto.Google.Protobuf.Timestamp (Timestamp)
import Proto.Peculiar.Insights.V1.Common qualified as P
import Proto.Peculiar.Insights.V1.Ingest qualified as P
import Proto.Peculiar.Insights.V1.Options qualified as P

fromItem :: P.Item -> (T.Text, Either T.Text Item)
fromItem item = case item ^. #maybe'kind of
  Nothing -> ("", Left "the item has no kind")
  Just (P.Item'Event event) -> (event ^. #id, ItemEvent <$> eventOf event)
  Just (P.Item'Identify identify) -> (identify ^. #id, ItemIdentify <$> identifyOf identify)
  Just (P.Item'ProfileUpdate profile) -> (profile ^. #id, ItemProfileUpdate <$> profileOf profile)
  Just (P.Item'CrashReport crash) -> (crash ^. #id, ItemCrashReport <$> crashOf crash)

idOf :: T.Text -> Either T.Text ItemId
idOf raw = maybe (Left "the id is not a uuid") (Right . ItemId) (UUID.fromText raw)

timeOf :: Timestamp -> UTCTime
timeOf stamp = posixSecondsToUTCTime (fromIntegral (stamp ^. #seconds) + fromIntegral (stamp ^. #nanos) / 1_000_000_000)

subjectOf :: P.Subject -> Subject
subjectOf subject =
  Subject
    { device = DeviceId (subject ^. #deviceId)
    , user = UserId <$> subject ^. #maybe'userId
    , session = SessionId (subject ^. #sessionId)
    }

platformOf :: P.Platform -> Platform
platformOf = \case
  P.PLATFORM_IOS -> Ios
  P.PLATFORM_ANDROID -> Android
  P.PLATFORM_MACOS -> Macos
  P.PLATFORM_WINDOWS -> Windows
  P.PLATFORM_LINUX -> Linux
  P.PLATFORM_WEB -> Web
  P.PLATFORM_SERVER -> Server
  _ -> UnknownPlatform

contextOf :: P.Context -> Context
contextOf context =
  Context
    { sdkName = context ^. #sdkName
    , sdkVersion = context ^. #sdkVersion
    , appVersion = context ^. #appVersion
    , appBuild = context ^. #appBuild
    , platform = platformOf (context ^. #platform)
    , osName = context ^. #osName
    , osVersion = context ^. #osVersion
    , deviceModel = context ^. #deviceModel
    , locale = context ^. #locale
    , timezone = context ^. #timezone
    , screenWidth = context ^. #screenWidth
    , screenHeight = context ^. #screenHeight
    }

valueOf :: P.Value -> Either T.Text Value
valueOf value = case value ^. #maybe'kind of
  Nothing -> Left "a value has no kind"
  Just (P.Value'StringValue text) -> Right (VString text)
  Just (P.Value'IntValue n) -> Right (VInt n)
  Just (P.Value'DoubleValue d) -> Right (VDouble d)
  Just (P.Value'BoolValue b) -> Right (VBool b)
  Just (P.Value'TimeValue stamp) -> Right (VTime (timeOf stamp))
  Just (P.Value'ListValue list) -> VList <$> traverse valueOf (list ^. #values)
  Just (P.Value'MapValue entries) -> VMap <$> traverse valueOf (entries ^. #entries)

propertiesOf :: Map.Map T.Text P.Value -> Either T.Text (Map.Map T.Text Value)
propertiesOf = traverse valueOf

eventOf :: P.Event -> Either T.Text Event
eventOf event = do
  identifier <- idOf (event ^. #id)
  properties <- propertiesOf (event ^. #properties)
  pure
    Event
      { id = identifier
      , time = timeOf (event ^. #time)
      , subject = subjectOf (event ^. #subject)
      , context = contextOf (event ^. #context)
      , name = event ^. #name
      , properties
      }

identifyOf :: P.Identify -> Either T.Text Identify
identifyOf identify = do
  identifier <- idOf (identify ^. #id)
  pure Identify{id = identifier, time = timeOf (identify ^. #time), device = DeviceId (identify ^. #deviceId), user = UserId (identify ^. #userId)}

profileOf :: P.ProfileUpdate -> Either T.Text ProfileUpdate
profileOf profile = do
  identifier <- idOf (profile ^. #id)
  operations <- traverse operationOf (profile ^. #operations)
  pure
    ProfileUpdate
      { id = identifier
      , time = timeOf (profile ^. #time)
      , device = DeviceId (profile ^. #deviceId)
      , user = UserId (profile ^. #userId)
      , operations
      }

operationOf :: P.ProfileOperation -> Either T.Text ProfileOperation
operationOf operation = case operation ^. #maybe'kind of
  Nothing -> Left "a profile operation has no kind"
  Just (P.ProfileOperation'Set value) -> Set key <$> valueOf value
  Just (P.ProfileOperation'SetOnce value) -> SetOnce key <$> valueOf value
  Just (P.ProfileOperation'Unset _) -> Right (Unset key)
  Just (P.ProfileOperation'Increment by) -> Right (Increment key by)
 where
  key = operation ^. #key

frameOf :: P.Frame -> Frame
frameOf frame =
  Frame
    { moduleName = frame ^. #module'
    , function = frame ^. #function
    , file = frame ^. #file
    , line = frame ^. #line
    , column = frame ^. #column
    , inApp = frame ^. #inApp
    , instructionAddress = frame ^. #maybe'instructionAddress
    , image = imageOf <$> frame ^. #maybe'image
    }

imageOf :: P.Image -> Image
imageOf image =
  Image
    { name = image ^. #name
    , identifier = image ^. #identifier
    , loadAddress = image ^. #loadAddress
    }

levelOf :: P.LogLevel -> LogLevel
levelOf = \case
  P.LOG_LEVEL_DEBUG -> Debug
  P.LOG_LEVEL_INFO -> Info
  P.LOG_LEVEL_WARNING -> Warning
  P.LOG_LEVEL_ERROR -> Error
  _ -> Info

logOf :: P.LogLine -> LogLine
logOf line = LogLine{time = timeOf (line ^. #time), level = levelOf (line ^. #level), message = line ^. #message}

crashOf :: P.CrashReport -> Either T.Text CrashReport
crashOf crash = do
  identifier <- idOf (crash ^. #id)
  customKeys <- propertiesOf (crash ^. #customKeys)
  pure
    CrashReport
      { id = identifier
      , time = timeOf (crash ^. #time)
      , subject = subjectOf (crash ^. #subject)
      , context = contextOf (crash ^. #context)
      , exceptionType = crash ^. #exceptionType
      , message = crash ^. #message
      , frames = fmap frameOf (crash ^. #frames)
      , rawStackTrace = crash ^. #rawStackTrace
      , fatal = crash ^. #fatal
      , thread = crash ^. #thread
      , customKeys
      , logs = fmap logOf (crash ^. #logs)
      }

purposeOf :: P.Purpose -> Maybe Purpose
purposeOf = \case
  P.PURPOSE_ANALYTICS -> Just Analytics
  P.PURPOSE_DIAGNOSTICS -> Just Diagnostics
  _ -> Nothing

stateOf :: P.ConsentState -> Maybe ConsentState
stateOf = \case
  P.CONSENT_STATE_GRANTED -> Just Granted
  P.CONSENT_STATE_WITHDRAWN -> Just Withdrawn
  _ -> Nothing

purposeStateOf :: P.PurposeState -> Maybe (Purpose, PurposeState)
purposeStateOf entry = do
  purpose <- purposeOf (entry ^. #purpose)
  state <- stateOf (entry ^. #state)
  pure (purpose, PurposeState{state, policyVersion = PolicyVersion (entry ^. #policyVersion)})

snapshotOf :: P.ConsentSnapshot -> Snapshot
snapshotOf snapshot = Snapshot (Map.fromList (mapMaybe purposeStateOf (snapshot ^. #purposes)))

consentOf :: P.RecordConsentRequest -> Either T.Text ConsentRecord
consentOf request = do
  identifier <- idOf (request ^. #id)
  (purpose, state) <- maybe (Left "the purpose or state is not recognised") Right (purposeStateOf (request ^. #purpose))
  pure
    ConsentRecord
      { id = identifier
      , time = timeOf (request ^. #time)
      , device = DeviceId (request ^. #deviceId)
      , user = UserId <$> request ^. #maybe'userId
      , purpose
      , state
      }

erasureOf :: P.RequestErasureRequest -> Either T.Text ErasureRequest
erasureOf request = do
  identifier <- idOf (request ^. #id)
  pure
    ErasureRequest
      { id = identifier
      , time = timeOf (request ^. #time)
      , device = DeviceId (request ^. #deviceId)
      , user = UserId <$> request ^. #maybe'userId
      }

itemOutcome :: T.Text -> P.Outcome -> T.Text -> P.ItemOutcome
itemOutcome identifier outcome reason = defMessage & #id .~ identifier & #outcome .~ outcome & #reason .~ reason
