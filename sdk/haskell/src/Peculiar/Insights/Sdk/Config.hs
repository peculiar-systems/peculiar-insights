module Peculiar.Insights.Sdk.Config
  ( Config (..)
  , Endpoint (..)
  , ConsentPolicy (..)
  , Bases (..)
  , Basis (..)
  , Diagnostic (..)
  , Rejection (..)
  , Failure (..)
  , Drop (..)
  , DropCause (..)
  , defaultConfig
  , policyConsent
  ) where

import Data.ByteString qualified as BS
import Data.Text qualified as T
import Peculiar.Insights.Sdk.Client (Endpoint (..))
import Peculiar.Insights.Sdk.Types (Consent (..), Grant (..), Purpose)
import Peculiar.Rpc qualified as Rpc

newtype Basis = Basis T.Text
  deriving stock (Eq, Show)

data Bases = Bases
  { analytics :: Maybe Basis
  , diagnostics :: Maybe Basis
  }
  deriving stock (Eq, Show)

data ConsentPolicy
  = Assumed Bases
  | Provided
  deriving stock (Eq, Show)

policyConsent :: ConsentPolicy -> Consent
policyConsent = \case
  Assumed bases -> Consent{analytics = grant <$> bases.analytics, diagnostics = grant <$> bases.diagnostics}
  Provided -> Consent{analytics = Nothing, diagnostics = Nothing}
 where
  grant (Basis basis) = Granted basis

data DropCause
  = QueueFull
  | NotConsented Purpose
  | NoUser
  | NotDelivered
  | AfterWithdrawal
  | AfterErasure
  deriving stock (Eq, Show)

data Rejection = Rejection
  { item :: T.Text
  , outcome :: T.Text
  , reason :: T.Text
  }
  deriving stock (Eq, Show)

data Failure = Failure
  { code :: Rpc.Code
  , message :: T.Text
  , willRetry :: Bool
  }
  deriving stock (Eq, Show)

data Drop = Drop
  { count :: Int
  , cause :: DropCause
  }
  deriving stock (Eq, Show)

data Diagnostic
  = Rejected Rejection
  | TransportFailed Failure
  | Dropped Drop
  | SpoolFailed T.Text
  deriving stock (Eq, Show)

data Config = Config
  { endpoint :: Endpoint
  , key :: BS.ByteString
  , service :: T.Text
  , appVersion :: T.Text
  , appBuild :: T.Text
  , consent :: ConsentPolicy
  , onDiagnostic :: Diagnostic -> IO ()
  , spool :: Maybe FilePath
  , batchSize :: Int
  , queueCapacity :: Int
  , flushIntervalMicros :: Int
  , callTimeoutSeconds :: Integer
  , logLimit :: Int
  }

defaultConfig :: Endpoint -> BS.ByteString -> T.Text -> ConsentPolicy -> Config
defaultConfig endpoint key service consent =
  Config
    { endpoint
    , key
    , service
    , appVersion = ""
    , appBuild = ""
    , consent
    , onDiagnostic = const (pure ())
    , spool = Nothing
    , batchSize = 200
    , queueCapacity = 10_000
    , flushIntervalMicros = 5_000_000
    , callTimeoutSeconds = 20
    , logLimit = 64
    }
