module Peculiar.Insights.Server.Db.Types
  ( DbError (..)
  , describeDbError
  , Stored (..)
  , ConsentRecord (..)
  , ErasureRequest (..)
  , Erased (..)
  , Retention (..)
  , Target (..)
  , Disposition (..)
  , stateOf
  , Unexpected (..)
  , db
  , single
  , uuidOf
  , deviceText
  , sessionText
  , userText
  , platformText
  , platformFromText
  ) where

import Control.Exception (Exception, throwIO)
import Data.Maybe (fromMaybe)
import Data.Text qualified as T
import Data.Time (UTCTime)
import Data.UUID.Types (UUID)
import Database.Beam (DatabaseSettings, liftIO)
import Database.Beam.Postgres (Pg, Postgres)
import Peculiar.Insights.Core.Consent (Purpose, PurposeState)
import Peculiar.Insights.Core.Enum (enumerate)
import Peculiar.Insights.Core.Item (DeviceId (..), ItemId (..), Platform (..), SessionId (..), UserId (..))
import Peculiar.Insights.Server.Migrate (MigrateError)
import Peculiar.Insights.Server.Projects (Registered)
import Peculiar.Insights.Server.Schema qualified as S

data DbError
  = Unavailable T.Text
  | Migration MigrateError
  deriving stock (Eq, Show)

describeDbError :: DbError -> T.Text
describeDbError = \case
  Unavailable reason -> "the database is unavailable: " <> reason
  Migration failure -> T.pack (show failure)

data Stored = Stored ItemId | Duplicate ItemId
  deriving stock (Eq, Show)

data ConsentRecord = ConsentRecord
  { id :: ItemId
  , time :: UTCTime
  , device :: DeviceId
  , user :: Maybe UserId
  , purpose :: Purpose
  , state :: PurposeState
  }
  deriving stock (Eq, Show)

data ErasureRequest = ErasureRequest
  { id :: ItemId
  , time :: UTCTime
  , device :: DeviceId
  , user :: Maybe UserId
  }
  deriving stock (Eq, Show)

data Erased = Erased | ErasureDuplicate
  deriving stock (Eq, Show)

data Retention = Retention
  { registered :: Registered
  , cutoff :: UTCTime
  }
  deriving stock (Eq, Show)

data Target = Target
  { slug :: T.Text
  , environment :: T.Text
  }
  deriving stock (Eq, Show)

data Disposition = Resolve | Ignore | Reopen
  deriving stock (Eq, Show, Enum, Bounded)

stateOf :: Disposition -> T.Text
stateOf = \case
  Resolve -> "resolved"
  Ignore -> "ignored"
  Reopen -> "open"

newtype Unexpected = Unexpected T.Text
  deriving stock (Show)
  deriving anyclass (Exception)

db :: DatabaseSettings Postgres S.InsightsDb
db = S.insightsDb

single :: T.Text -> [a] -> Pg a
single what = \case
  [one] -> pure one
  rows -> liftIO (throwIO (Unexpected (what <> " returned " <> T.pack (show (length rows)) <> " rows")))

uuidOf :: ItemId -> UUID
uuidOf (ItemId identifier) = identifier

deviceText :: DeviceId -> T.Text
deviceText (DeviceId identifier) = identifier

sessionText :: SessionId -> T.Text
sessionText (SessionId identifier) = identifier

userText :: UserId -> T.Text
userText (UserId identifier) = identifier

platformText :: Platform -> T.Text
platformText = \case
  Ios -> "ios"
  Android -> "android"
  Macos -> "macos"
  Windows -> "windows"
  Linux -> "linux"
  Web -> "web"
  Server -> "server"
  UnknownPlatform -> "unknown"

platformFromText :: T.Text -> Platform
platformFromText name = fromMaybe UnknownPlatform (lookup name [(platformText platform, platform) | platform <- enumerate])
