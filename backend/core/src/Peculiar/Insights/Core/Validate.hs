module Peculiar.Insights.Core.Validate
  ( Limits (..)
  , defaultLimits
  , Invalid (..)
  , validate
  , describeInvalid
  ) where

import Data.Map.Strict qualified as Map
import Data.Text qualified as T
import Data.Traversable (for)
import Optics.Core ((&), (.~))
import Peculiar.Insights.Core.Item
import Peculiar.Insights.Core.Value (Value, depth, longestString)

data Limits = Limits
  { maxItems :: Int
  , maxIdentifierLength :: Int
  , maxNameLength :: Int
  , maxKeyLength :: Int
  , maxStringLength :: Int
  , maxProperties :: Int
  , maxDepth :: Int
  , maxOperations :: Int
  , maxFrames :: Int
  , maxLogs :: Int
  , maxMessageLength :: Int
  , maxStackTraceLength :: Int
  }
  deriving stock (Eq, Show)

defaultLimits :: Limits
defaultLimits =
  Limits
    { maxItems = 1000
    , maxIdentifierLength = 128
    , maxNameLength = 128
    , maxKeyLength = 128
    , maxStringLength = 4096
    , maxProperties = 256
    , maxDepth = 3
    , maxOperations = 64
    , maxFrames = 256
    , maxLogs = 128
    , maxMessageLength = 4096
    , maxStackTraceLength = 65536
    }

data Invalid
  = EmptyDevice
  | EmptyUser
  | EmptySession
  | EmptyName
  | EmptyKey
  | EmptyExceptionType
  | IdentifierTooLong T.Text
  | NameTooLong
  | KeyTooLong T.Text
  | StringTooLong T.Text
  | TooDeep T.Text
  | TooManyProperties
  | TooManyOperations
  deriving stock (Eq, Show)

describeInvalid :: Invalid -> T.Text
describeInvalid = \case
  EmptyDevice -> "device id is empty"
  EmptyUser -> "user id is empty"
  EmptySession -> "session id is empty"
  EmptyName -> "event name is empty"
  EmptyKey -> "a property key is empty"
  EmptyExceptionType -> "exception type is empty"
  IdentifierTooLong which -> which <> " is longer than allowed"
  NameTooLong -> "event name is longer than allowed"
  KeyTooLong key -> "property " <> key <> " has a key longer than allowed"
  StringTooLong key -> "property " <> key <> " holds a string longer than allowed"
  TooDeep key -> "property " <> key <> " is nested deeper than allowed"
  TooManyProperties -> "too many properties"
  TooManyOperations -> "too many profile operations"

validate :: Limits -> Item -> Either Invalid Item
validate limits = \case
  ItemEvent event -> ItemEvent <$> validateEvent limits event
  ItemIdentify identify -> ItemIdentify <$> validateIdentify limits identify
  ItemProfileUpdate update -> ItemProfileUpdate <$> validateProfileUpdate limits update
  ItemCrashReport crash -> ItemCrashReport <$> validateCrash limits crash

validateEvent :: Limits -> Event -> Either Invalid Event
validateEvent limits event = do
  subject <- validateSubject limits event.subject
  name <- validateName limits event.name
  properties <- validateProperties limits event.properties
  pure (event & #subject .~ subject & #name .~ name & #properties .~ properties)

validateIdentify :: Limits -> Identify -> Either Invalid Identify
validateIdentify limits identify = do
  device <- validateDevice limits identify.device
  user <- validateUser limits identify.user
  pure (identify & #device .~ device & #user .~ user)

validateProfileUpdate :: Limits -> ProfileUpdate -> Either Invalid ProfileUpdate
validateProfileUpdate limits update = do
  device <- validateDevice limits update.device
  user <- validateUser limits update.user
  if length update.operations > limits.maxOperations then Left TooManyOperations else Right ()
  operations <- for update.operations (validateOperation limits)
  pure (update & #device .~ device & #user .~ user & #operations .~ operations)

validateCrash :: Limits -> CrashReport -> Either Invalid CrashReport
validateCrash limits crash = do
  subject <- validateSubject limits crash.subject
  if T.null crash.exceptionType then Left EmptyExceptionType else Right ()
  customKeys <- validateProperties limits crash.customKeys
  frames <- traverse (validateFrame limits) (take limits.maxFrames crash.frames)
  pure
    ( crash
        & #subject
        .~ subject
        & #exceptionType
        .~ T.take limits.maxNameLength crash.exceptionType
        & #message
        .~ T.take limits.maxMessageLength crash.message
        & #frames
        .~ frames
        & #rawStackTrace
        .~ T.take limits.maxStackTraceLength crash.rawStackTrace
        & #thread
        .~ T.take limits.maxNameLength crash.thread
        & #customKeys
        .~ customKeys
        & #logs
        .~ take limits.maxLogs (fmap (truncateLog limits) crash.logs)
    )

validateFrame :: Limits -> Frame -> Either Invalid Frame
validateFrame limits frame = do
  image <- traverse (validateImage limits) frame.image
  pure
    frame
      { moduleName = T.take limits.maxStringLength frame.moduleName
      , function = T.take limits.maxStringLength frame.function
      , file = T.take limits.maxStringLength frame.file
      , image
      }

validateImage :: Limits -> Image -> Either Invalid Image
validateImage limits image
  | T.length image.identifier > limits.maxIdentifierLength = Left (IdentifierTooLong "image identifier")
  | otherwise = Right (image & #name .~ T.take limits.maxStringLength image.name)

truncateLog :: Limits -> LogLine -> LogLine
truncateLog limits line = line & #message .~ T.take limits.maxMessageLength line.message

validateSubject :: Limits -> Subject -> Either Invalid Subject
validateSubject limits subject = do
  device <- validateDevice limits subject.device
  user <- traverse (validateUser limits) subject.user
  session <- validateSession limits subject.session
  pure Subject{device, user, session}

validateDevice :: Limits -> DeviceId -> Either Invalid DeviceId
validateDevice limits (DeviceId text) = DeviceId <$> identifier limits "device id" EmptyDevice text

validateUser :: Limits -> UserId -> Either Invalid UserId
validateUser limits (UserId text) = UserId <$> identifier limits "user id" EmptyUser text

validateSession :: Limits -> SessionId -> Either Invalid SessionId
validateSession limits (SessionId text) = SessionId <$> identifier limits "session id" EmptySession text

identifier :: Limits -> T.Text -> Invalid -> T.Text -> Either Invalid T.Text
identifier limits which empty text
  | T.null text = Left empty
  | T.length text > limits.maxIdentifierLength = Left (IdentifierTooLong which)
  | otherwise = Right text

validateName :: Limits -> T.Text -> Either Invalid T.Text
validateName limits name
  | T.null name = Left EmptyName
  | T.length name > limits.maxNameLength = Left NameTooLong
  | otherwise = Right name

validateProperties :: Limits -> Map.Map T.Text Value -> Either Invalid (Map.Map T.Text Value)
validateProperties limits properties
  | Map.size properties > limits.maxProperties = Left TooManyProperties
  | otherwise = Map.traverseWithKey (validateProperty limits) properties

validateProperty :: Limits -> T.Text -> Value -> Either Invalid Value
validateProperty limits key value
  | T.null key = Left EmptyKey
  | T.length key > limits.maxKeyLength = Left (KeyTooLong key)
  | depth value > limits.maxDepth = Left (TooDeep key)
  | longestString value > limits.maxStringLength = Left (StringTooLong key)
  | otherwise = Right value

validateOperation :: Limits -> ProfileOperation -> Either Invalid ProfileOperation
validateOperation limits = \case
  Set key value -> Set key <$> validateProperty limits key value
  SetOnce key value -> SetOnce key <$> validateProperty limits key value
  Unset key -> Unset <$> validateKey limits key
  Increment key by -> (`Increment` by) <$> validateKey limits key

validateKey :: Limits -> T.Text -> Either Invalid T.Text
validateKey limits key
  | T.null key = Left EmptyKey
  | T.length key > limits.maxKeyLength = Left (KeyTooLong key)
  | otherwise = Right key
