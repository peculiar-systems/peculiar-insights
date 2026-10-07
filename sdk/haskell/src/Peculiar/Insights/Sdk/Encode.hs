module Peculiar.Insights.Sdk.Encode
  ( encodeItem
  , encodeConsent
  , decodeConsent
  , itemIdentifier
  , Described (..)
  , described
  , encodeContext
  , timestamp
  ) where

import Data.Map.Strict qualified as Map
import Data.ProtoLens (defMessage)
import Data.ProtoLens.Labels ()
import Data.Text qualified as T
import Data.Time (UTCTime)
import Data.Time.Clock.POSIX (posixSecondsToUTCTime, utcTimeToPOSIXSeconds)
import Lens.Family2 ((&), (.~), (^.))
import Peculiar.Insights.Sdk.Types
import Proto.Google.Protobuf.Timestamp (Timestamp)
import Proto.Peculiar.Insights.V1.Common qualified as P
import Proto.Peculiar.Insights.V1.Ingest qualified as P
import Proto.Peculiar.Insights.V1.Options qualified as P

timestamp :: UTCTime -> Timestamp
timestamp at =
  let total = utcTimeToPOSIXSeconds at
      seconds = floor total :: Integer
      nanos = round ((total - fromInteger seconds) * 1_000_000_000) :: Integer
   in defMessage & #seconds .~ fromInteger seconds & #nanos .~ fromInteger nanos

encodeValue :: Value -> P.Value
encodeValue = \case
  VString text -> defMessage & #stringValue .~ text
  VInt n -> defMessage & #intValue .~ n
  VDouble d -> defMessage & #doubleValue .~ d
  VBool b -> defMessage & #boolValue .~ b
  VTime at -> defMessage & #timeValue .~ timestamp at
  VList values -> defMessage & #listValue .~ (defMessage & #values .~ fmap encodeValue values)
  VMap entries -> defMessage & #mapValue .~ (defMessage & #entries .~ fmap encodeValue entries)

encodeProperties :: Map.Map T.Text Value -> Map.Map T.Text P.Value
encodeProperties = fmap encodeValue

encodeSubject :: Subject -> P.Subject
encodeSubject subject =
  defMessage
    & #deviceId .~ deviceText subject.device
    & #maybe'userId .~ fmap userText subject.user
    & #sessionId .~ sessionText subject.session

deviceText :: DeviceId -> T.Text
deviceText (DeviceId text) = text

userText :: UserId -> T.Text
userText (UserId text) = text

sessionText :: SessionId -> T.Text
sessionText (SessionId text) = text

encodePlatform :: Platform -> P.Platform
encodePlatform = \case
  Server -> P.PLATFORM_SERVER
  Linux -> P.PLATFORM_LINUX
  Macos -> P.PLATFORM_MACOS
  Windows -> P.PLATFORM_WINDOWS

encodeContext :: T.Text -> Context -> P.Context
encodeContext sdkVersion context =
  defMessage
    & #sdkName .~ "peculiar-insights-haskell"
    & #sdkVersion .~ sdkVersion
    & #appVersion .~ context.appVersion
    & #appBuild .~ context.appBuild
    & #platform .~ encodePlatform context.platform
    & #osName .~ context.osName
    & #osVersion .~ context.osVersion
    & #deviceModel .~ context.hostModel
    & #locale .~ context.locale
    & #timezone .~ context.timezone

encodeOperation :: ProfileOperation -> P.ProfileOperation
encodeOperation = \case
  Set key value -> defMessage & #key .~ key & #set .~ encodeValue value
  SetOnce key value -> defMessage & #key .~ key & #setOnce .~ encodeValue value
  Unset key -> defMessage & #key .~ key & #unset .~ defMessage

encodeFrame :: Frame -> P.Frame
encodeFrame frame =
  defMessage
    & #module' .~ frame.moduleName
    & #function .~ frame.function
    & #file .~ frame.file
    & #line .~ frame.line
    & #column .~ frame.column
    & #inApp .~ frame.inApp

encodeLevel :: LogLevel -> P.LogLevel
encodeLevel = \case
  Debug -> P.LOG_LEVEL_DEBUG
  Info -> P.LOG_LEVEL_INFO
  Warning -> P.LOG_LEVEL_WARNING
  Error -> P.LOG_LEVEL_ERROR

encodeLog :: LogLine -> P.LogLine
encodeLog line = defMessage & #time .~ timestamp line.time & #level .~ encodeLevel line.level & #message .~ line.message

encodeItem :: T.Text -> P.Context -> T.Text -> UTCTime -> Item -> P.Item
encodeItem _ context identifier at = \case
  Track subject name properties ->
    defMessage
      & #event
        .~ ( defMessage
               & #id .~ identifier
               & #time .~ timestamp at
               & #subject .~ encodeSubject subject
               & #context .~ context
               & #name .~ name
               & #properties .~ encodeProperties properties
           )
  Identify device user ->
    defMessage & #identify .~ (defMessage & #id .~ identifier & #time .~ timestamp at & #deviceId .~ deviceText device & #userId .~ userText user)
  Profile device user operations ->
    defMessage
      & #profileUpdate
        .~ ( defMessage
               & #id .~ identifier
               & #time .~ timestamp at
               & #deviceId .~ deviceText device
               & #userId .~ userText user
               & #operations .~ fmap encodeOperation operations
           )
  Crash subject report ->
    defMessage
      & #crashReport
        .~ ( defMessage
               & #id .~ identifier
               & #time .~ timestamp at
               & #subject .~ encodeSubject subject
               & #context .~ context
               & #exceptionType .~ report.exceptionType
               & #message .~ report.message
               & #frames .~ fmap encodeFrame report.frames
               & #rawStackTrace .~ report.rawStackTrace
               & #fatal .~ report.fatal
               & #thread .~ report.thread
               & #customKeys .~ encodeProperties report.customKeys
               & #logs .~ fmap encodeLog report.logs
           )

encodeConsent :: Consent -> P.ConsentSnapshot
encodeConsent consent =
  defMessage & #purposes .~ [entry P.PURPOSE_ANALYTICS grant | Just grant <- [consent.analytics]] <> [entry P.PURPOSE_DIAGNOSTICS grant | Just grant <- [consent.diagnostics]]
 where
  entry purpose grant =
    defMessage
      & #purpose .~ purpose
      & #state .~ (case grant of Granted _ -> P.CONSENT_STATE_GRANTED; Withdrawn _ -> P.CONSENT_STATE_WITHDRAWN)
      & #policyVersion .~ (case grant of Granted version -> version; Withdrawn version -> version)

decodeConsent :: P.ConsentSnapshot -> Consent
decodeConsent snapshot = Consent{analytics = granted P.PURPOSE_ANALYTICS, diagnostics = granted P.PURPOSE_DIAGNOSTICS}
 where
  granted purpose = case [entry | entry <- snapshot ^. #purposes, entry ^. #purpose == purpose] of
    entry : _ -> case entry ^. #state of
      P.CONSENT_STATE_GRANTED -> Just (Granted (entry ^. #policyVersion))
      P.CONSENT_STATE_WITHDRAWN -> Just (Withdrawn (entry ^. #policyVersion))
      _ -> Nothing
    [] -> Nothing

itemIdentifier :: P.Item -> Maybe T.Text
itemIdentifier item = case item ^. #maybe'kind of
  Just (P.Item'Event event) -> Just (event ^. #id)
  Just (P.Item'Identify identify) -> Just (identify ^. #id)
  Just (P.Item'ProfileUpdate update) -> Just (update ^. #id)
  Just (P.Item'CrashReport report) -> Just (report ^. #id)
  Nothing -> Nothing

data Described = Described
  { identifier :: T.Text
  , purpose :: Purpose
  , device :: T.Text
  , user :: Maybe T.Text
  , time :: UTCTime
  }
  deriving stock (Eq, Show)

described :: P.Item -> Maybe Described
described item = case item ^. #maybe'kind of
  Just (P.Item'Event event) ->
    Just (whose Analytics (event ^. #id) (event ^. #time) (event ^. #subject . #deviceId) (event ^. #subject . #maybe'userId))
  Just (P.Item'Identify identify) ->
    Just (whose Analytics (identify ^. #id) (identify ^. #time) (identify ^. #deviceId) (Just (identify ^. #userId)))
  Just (P.Item'ProfileUpdate update) ->
    Just (whose Analytics (update ^. #id) (update ^. #time) (update ^. #deviceId) (Just (update ^. #userId)))
  Just (P.Item'CrashReport report) ->
    Just (whose Diagnostics (report ^. #id) (report ^. #time) (report ^. #subject . #deviceId) (report ^. #subject . #maybe'userId))
  Nothing -> Nothing
 where
  whose purpose identifier stamp device user =
    Described
      { identifier
      , purpose
      , device
      , user
      , time = posixSecondsToUTCTime (fromIntegral (stamp ^. #seconds) + fromIntegral (stamp ^. #nanos) / 1_000_000_000)
      }
