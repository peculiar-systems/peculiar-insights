module Peculiar.Insights.Core.Item
  ( ItemId (..)
  , DeviceId (..)
  , UserId (..)
  , SessionId (..)
  , Subject (..)
  , Platform (..)
  , Context (..)
  , Event (..)
  , Identify (..)
  , ProfileOperation (..)
  , ProfileUpdate (..)
  , Frame (..)
  , Image (..)
  , LogLevel (..)
  , LogLine (..)
  , CrashReport (..)
  , Item (..)
  , itemId
  , itemTime
  , itemPurpose
  , itemDevice
  , setTime
  ) where

import Data.Aeson (FromJSON, ToJSON)
import Data.Map.Strict qualified as Map
import Data.Text qualified as T
import Data.Time (UTCTime)
import Data.UUID.Types (UUID)
import Data.Word (Word32, Word64)
import Deriving.Aeson (CamelToSnake, ConstructorTagModifier, CustomJSON (..), FieldLabelModifier)
import GHC.Generics (Generic)
import Optics.Core ((&), (.~))
import Peculiar.Insights.Core.Consent (Purpose (..))
import Peculiar.Insights.Core.Value (Value)

type Snake = CustomJSON '[FieldLabelModifier '[CamelToSnake], ConstructorTagModifier '[CamelToSnake]]

newtype ItemId = ItemId UUID
  deriving stock (Eq, Ord, Show)

newtype DeviceId = DeviceId T.Text
  deriving stock (Eq, Ord, Show)

newtype UserId = UserId T.Text
  deriving stock (Eq, Ord, Show)

newtype SessionId = SessionId T.Text
  deriving stock (Eq, Ord, Show)

data Subject = Subject
  { device :: DeviceId
  , user :: Maybe UserId
  , session :: SessionId
  }
  deriving stock (Eq, Show, Generic)

data Platform
  = Ios
  | Android
  | Macos
  | Windows
  | Linux
  | Web
  | Server
  | UnknownPlatform
  deriving stock (Eq, Ord, Show, Enum, Bounded, Generic)
  deriving (FromJSON, ToJSON) via Snake Platform

data Context = Context
  { sdkName :: T.Text
  , sdkVersion :: T.Text
  , appVersion :: T.Text
  , appBuild :: T.Text
  , platform :: Platform
  , osName :: T.Text
  , osVersion :: T.Text
  , deviceModel :: T.Text
  , locale :: T.Text
  , timezone :: T.Text
  , screenWidth :: Word32
  , screenHeight :: Word32
  }
  deriving stock (Eq, Show, Generic)
  deriving (FromJSON, ToJSON) via Snake Context

data Event = Event
  { id :: ItemId
  , time :: UTCTime
  , subject :: Subject
  , context :: Context
  , name :: T.Text
  , properties :: Map.Map T.Text Value
  }
  deriving stock (Eq, Show, Generic)

data Identify = Identify
  { id :: ItemId
  , time :: UTCTime
  , device :: DeviceId
  , user :: UserId
  }
  deriving stock (Eq, Show, Generic)

data ProfileOperation
  = Set T.Text Value
  | SetOnce T.Text Value
  | Unset T.Text
  | Increment T.Text Double
  deriving stock (Eq, Show)

data ProfileUpdate = ProfileUpdate
  { id :: ItemId
  , time :: UTCTime
  , device :: DeviceId
  , user :: UserId
  , operations :: [ProfileOperation]
  }
  deriving stock (Eq, Show, Generic)

data Frame = Frame
  { moduleName :: T.Text
  , function :: T.Text
  , file :: T.Text
  , line :: Word32
  , column :: Word32
  , inApp :: Bool
  , instructionAddress :: Maybe Word64
  , image :: Maybe Image
  }
  deriving stock (Eq, Show, Generic)
  deriving (FromJSON, ToJSON) via Snake Frame

data Image = Image
  { name :: T.Text
  , identifier :: T.Text
  , loadAddress :: Word64
  }
  deriving stock (Eq, Show, Generic)
  deriving (FromJSON, ToJSON) via Snake Image

data LogLevel = Debug | Info | Warning | Error
  deriving stock (Eq, Ord, Show, Enum, Bounded, Generic)
  deriving (FromJSON, ToJSON) via Snake LogLevel

data LogLine = LogLine
  { time :: UTCTime
  , level :: LogLevel
  , message :: T.Text
  }
  deriving stock (Eq, Show, Generic)
  deriving (FromJSON, ToJSON) via Snake LogLine

data CrashReport = CrashReport
  { id :: ItemId
  , time :: UTCTime
  , subject :: Subject
  , context :: Context
  , exceptionType :: T.Text
  , message :: T.Text
  , frames :: [Frame]
  , rawStackTrace :: T.Text
  , fatal :: Bool
  , thread :: T.Text
  , customKeys :: Map.Map T.Text Value
  , logs :: [LogLine]
  }
  deriving stock (Eq, Show, Generic)

data Item
  = ItemEvent Event
  | ItemIdentify Identify
  | ItemProfileUpdate ProfileUpdate
  | ItemCrashReport CrashReport
  deriving stock (Eq, Show)

itemId :: Item -> ItemId
itemId = \case
  ItemEvent event -> event.id
  ItemIdentify identify -> identify.id
  ItemProfileUpdate update -> update.id
  ItemCrashReport crash -> crash.id

itemTime :: Item -> UTCTime
itemTime = \case
  ItemEvent event -> event.time
  ItemIdentify identify -> identify.time
  ItemProfileUpdate update -> update.time
  ItemCrashReport crash -> crash.time

itemPurpose :: Item -> Purpose
itemPurpose = \case
  ItemCrashReport _ -> Diagnostics
  _ -> Analytics

itemDevice :: Item -> DeviceId
itemDevice = \case
  ItemEvent event -> event.subject.device
  ItemIdentify identify -> identify.device
  ItemProfileUpdate update -> update.device
  ItemCrashReport crash -> crash.subject.device

setTime :: UTCTime -> Item -> Item
setTime at = \case
  ItemEvent event -> ItemEvent (event & #time .~ at)
  ItemIdentify identify -> ItemIdentify (identify & #time .~ at)
  ItemProfileUpdate update -> ItemProfileUpdate (update & #time .~ at)
  ItemCrashReport crash -> ItemCrashReport (crash & #time .~ at)
