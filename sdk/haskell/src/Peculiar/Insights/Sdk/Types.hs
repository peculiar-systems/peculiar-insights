module Peculiar.Insights.Sdk.Types
  ( Value (..)
  , Purpose (..)
  , Grant (..)
  , Consent (..)
  , noConsent
  , permits
  , purposeName
  , UserId (..)
  , DeviceId (..)
  , SessionId (..)
  , Subject (..)
  , Platform (..)
  , Context (..)
  , ProfileOperation (..)
  , Frame (..)
  , LogLevel (..)
  , LogLine (..)
  , ErrorReport (..)
  , Item (..)
  , itemPurpose
  ) where

import Data.Int (Int64)
import Data.Map.Strict qualified as Map
import Data.Text qualified as T
import Data.Time (UTCTime)
import Data.Word (Word32)

data Value
  = VString T.Text
  | VInt Int64
  | VDouble Double
  | VBool Bool
  | VTime UTCTime
  | VList [Value]
  | VMap (Map.Map T.Text Value)
  deriving stock (Eq, Show)

data Purpose = Analytics | Diagnostics
  deriving stock (Eq, Ord, Show, Enum, Bounded)

purposeName :: Purpose -> T.Text
purposeName = \case
  Analytics -> "analytics"
  Diagnostics -> "diagnostics"

data Grant = Granted T.Text | Withdrawn T.Text
  deriving stock (Eq, Ord, Show)

data Consent = Consent
  { analytics :: Maybe Grant
  , diagnostics :: Maybe Grant
  }
  deriving stock (Eq, Ord, Show)

noConsent :: Consent
noConsent = Consent{analytics = Nothing, diagnostics = Nothing}

permits :: Consent -> Purpose -> Bool
permits consent = \case
  Analytics -> granted consent.analytics
  Diagnostics -> granted consent.diagnostics
 where
  granted = \case
    Just (Granted _) -> True
    _ -> False

newtype UserId = UserId T.Text
  deriving stock (Eq, Ord, Show)

newtype DeviceId = DeviceId T.Text
  deriving stock (Eq, Ord, Show)

newtype SessionId = SessionId T.Text
  deriving stock (Eq, Ord, Show)

data Subject = Subject
  { device :: DeviceId
  , user :: Maybe UserId
  , session :: SessionId
  }
  deriving stock (Eq, Show)

data Platform = Server | Linux | Macos | Windows
  deriving stock (Eq, Show, Enum, Bounded)

data Context = Context
  { appVersion :: T.Text
  , appBuild :: T.Text
  , platform :: Platform
  , osName :: T.Text
  , osVersion :: T.Text
  , hostModel :: T.Text
  , locale :: T.Text
  , timezone :: T.Text
  }
  deriving stock (Eq, Show)

data ProfileOperation
  = Set T.Text Value
  | SetOnce T.Text Value
  | Unset T.Text
  deriving stock (Eq, Show)

data Frame = Frame
  { moduleName :: T.Text
  , function :: T.Text
  , file :: T.Text
  , line :: Word32
  , column :: Word32
  , inApp :: Bool
  }
  deriving stock (Eq, Show)

data LogLevel = Debug | Info | Warning | Error
  deriving stock (Eq, Show, Enum, Bounded)

data LogLine = LogLine
  { time :: UTCTime
  , level :: LogLevel
  , message :: T.Text
  }
  deriving stock (Eq, Show)

data ErrorReport = ErrorReport
  { exceptionType :: T.Text
  , message :: T.Text
  , frames :: [Frame]
  , rawStackTrace :: T.Text
  , fatal :: Bool
  , thread :: T.Text
  , customKeys :: Map.Map T.Text Value
  , logs :: [LogLine]
  }
  deriving stock (Eq, Show)

data Item
  = Track Subject T.Text (Map.Map T.Text Value)
  | Identify DeviceId UserId
  | Profile DeviceId UserId [ProfileOperation]
  | Crash Subject ErrorReport
  deriving stock (Eq, Show)

itemPurpose :: Item -> Purpose
itemPurpose = \case
  Crash _ _ -> Diagnostics
  _ -> Analytics
