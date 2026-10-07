{-# LANGUAGE StrictData #-}

module Peculiar.Insights.Server.Schema
  ( ProjectT (..)
  , PersonT (..)
  , DeviceT (..)
  , IngestedT (..)
  , EventT (..)
  , SessionT (..)
  , IssueT (..)
  , CrashT (..)
  , ConsentT (..)
  , ErasureT (..)
  , SymbolBuildT (..)
  , SymbolKindT (..)
  , SymbolEntryT (..)
  , PrimaryKey (..)
  , InsightsDb (..)
  , insightsDb
  ) where

import Data.Aeson qualified as Aeson
import Data.Char (isUpper, toLower)
import Data.Int (Int32, Int64)
import Data.List.NonEmpty (NonEmpty (..))
import Data.Text qualified as T
import Data.Time (UTCTime)
import Data.UUID.Types (UUID)
import Database.Beam
import Database.Beam.Backend.SQL.Types (SqlSerial)
import Database.Beam.Postgres (PgJSONB)
import Database.Beam.Schema.Tables (renamingFields)

data ProjectT f = Project
  { id :: C f (SqlSerial Int32)
  , slug :: C f T.Text
  , environment :: C f T.Text
  }
  deriving stock (Generic)
  deriving anyclass (Beamable)

instance Table ProjectT where
  data PrimaryKey ProjectT f = ProjectKey (C f (SqlSerial Int32))
    deriving stock (Generic)
    deriving anyclass (Beamable)
  primaryKey = ProjectKey . (.id)

data PersonT f = Person
  { id :: C f (SqlSerial Int64)
  , projectId :: C f Int32
  , userId :: C f T.Text
  , properties :: C f (PgJSONB Aeson.Value)
  , firstSeen :: C f UTCTime
  , lastSeen :: C f UTCTime
  }
  deriving stock (Generic)
  deriving anyclass (Beamable)

instance Table PersonT where
  data PrimaryKey PersonT f = PersonKey (C f (SqlSerial Int64))
    deriving stock (Generic)
    deriving anyclass (Beamable)
  primaryKey = PersonKey . (.id)

data DeviceT f = Device
  { projectId :: C f Int32
  , id :: C f T.Text
  , personId :: C f (Maybe Int64)
  , firstSeen :: C f UTCTime
  , lastSeen :: C f UTCTime
  }
  deriving stock (Generic)
  deriving anyclass (Beamable)

instance Table DeviceT where
  data PrimaryKey DeviceT f = DeviceKey (C f Int32) (C f T.Text)
    deriving stock (Generic)
    deriving anyclass (Beamable)
  primaryKey device = DeviceKey device.projectId device.id

data IngestedT f = Ingested
  { projectId :: C f Int32
  , id :: C f UUID
  , receivedAt :: C f UTCTime
  }
  deriving stock (Generic)
  deriving anyclass (Beamable)

instance Table IngestedT where
  data PrimaryKey IngestedT f = IngestedKey (C f Int32) (C f UUID)
    deriving stock (Generic)
    deriving anyclass (Beamable)
  primaryKey ingested = IngestedKey ingested.projectId ingested.id

data EventT f = Event
  { projectId :: C f Int32
  , id :: C f UUID
  , time :: C f UTCTime
  , clientTime :: C f UTCTime
  , receivedAt :: C f UTCTime
  , deviceId :: C f T.Text
  , personId :: C f (Maybe Int64)
  , sessionId :: C f T.Text
  , name :: C f T.Text
  , properties :: C f (PgJSONB Aeson.Value)
  , context :: C f (PgJSONB Aeson.Value)
  , appVersion :: C f T.Text
  , appBuild :: C f T.Text
  , platform :: C f T.Text
  }
  deriving stock (Generic)
  deriving anyclass (Beamable)

instance Table EventT where
  data PrimaryKey EventT f = EventKey (C f Int32) (C f UUID)
    deriving stock (Generic)
    deriving anyclass (Beamable)
  primaryKey event = EventKey event.projectId event.id

data SessionT f = Session
  { projectId :: C f Int32
  , id :: C f T.Text
  , deviceId :: C f T.Text
  , personId :: C f (Maybe Int64)
  , startedAt :: C f UTCTime
  , lastSeenAt :: C f UTCTime
  , crashed :: C f Bool
  , appVersion :: C f T.Text
  , platform :: C f T.Text
  }
  deriving stock (Generic)
  deriving anyclass (Beamable)

instance Table SessionT where
  data PrimaryKey SessionT f = SessionKey (C f Int32) (C f T.Text)
    deriving stock (Generic)
    deriving anyclass (Beamable)
  primaryKey session = SessionKey session.projectId session.id

data IssueT f = Issue
  { id :: C f (SqlSerial Int64)
  , projectId :: C f Int32
  , fingerprint :: C f T.Text
  , title :: C f T.Text
  , exceptionType :: C f T.Text
  , state :: C f T.Text
  , firstSeen :: C f UTCTime
  , lastSeen :: C f UTCTime
  , firstBuild :: C f T.Text
  , lastBuild :: C f T.Text
  , resolvedAt :: C f (Maybe UTCTime)
  , resolvedBuild :: C f (Maybe T.Text)
  , regressedAt :: C f (Maybe UTCTime)
  , regrouped :: C f Bool
  }
  deriving stock (Generic)
  deriving anyclass (Beamable)

instance Table IssueT where
  data PrimaryKey IssueT f = IssueKey (C f (SqlSerial Int64))
    deriving stock (Generic)
    deriving anyclass (Beamable)
  primaryKey = IssueKey . (.id)

data CrashT f = Crash
  { projectId :: C f Int32
  , id :: C f UUID
  , issueId :: C f Int64
  , time :: C f UTCTime
  , clientTime :: C f UTCTime
  , receivedAt :: C f UTCTime
  , deviceId :: C f T.Text
  , personId :: C f (Maybe Int64)
  , sessionId :: C f T.Text
  , exceptionType :: C f T.Text
  , message :: C f T.Text
  , frames :: C f (PgJSONB Aeson.Value)
  , rawStackTrace :: C f T.Text
  , fatal :: C f Bool
  , thread :: C f T.Text
  , customKeys :: C f (PgJSONB Aeson.Value)
  , logs :: C f (PgJSONB Aeson.Value)
  , context :: C f (PgJSONB Aeson.Value)
  , appVersion :: C f T.Text
  , appBuild :: C f T.Text
  , platform :: C f T.Text
  , rawFrames :: C f (PgJSONB Aeson.Value)
  }
  deriving stock (Generic)
  deriving anyclass (Beamable)

instance Table CrashT where
  data PrimaryKey CrashT f = CrashKey (C f Int32) (C f UUID)
    deriving stock (Generic)
    deriving anyclass (Beamable)
  primaryKey crash = CrashKey crash.projectId crash.id

data ConsentT f = Consent
  { projectId :: C f Int32
  , id :: C f UUID
  , deviceId :: C f T.Text
  , personId :: C f (Maybe Int64)
  , purpose :: C f T.Text
  , state :: C f T.Text
  , policyVersion :: C f T.Text
  , time :: C f UTCTime
  , receivedAt :: C f UTCTime
  }
  deriving stock (Generic)
  deriving anyclass (Beamable)

instance Table ConsentT where
  data PrimaryKey ConsentT f = ConsentKey (C f Int32) (C f UUID)
    deriving stock (Generic)
    deriving anyclass (Beamable)
  primaryKey consent = ConsentKey consent.projectId consent.id

data ErasureT f = Erasure
  { projectId :: C f Int32
  , id :: C f UUID
  , deviceId :: C f T.Text
  , personId :: C f (Maybe Int64)
  , requestedAt :: C f UTCTime
  , completedAt :: C f UTCTime
  }
  deriving stock (Generic)
  deriving anyclass (Beamable)

instance Table ErasureT where
  data PrimaryKey ErasureT f = ErasureKey (C f Int32) (C f UUID)
    deriving stock (Generic)
    deriving anyclass (Beamable)
  primaryKey erasure = ErasureKey erasure.projectId erasure.id

data SymbolBuildT f = SymbolBuild
  { id :: C f (SqlSerial Int32)
  , project :: C f T.Text
  , build :: C f T.Text
  , uploadedAt :: C f UTCTime
  , reported :: C f Bool
  }
  deriving stock (Generic)
  deriving anyclass (Beamable)

instance Table SymbolBuildT where
  data PrimaryKey SymbolBuildT f = SymbolBuildKey (C f (SqlSerial Int32))
    deriving stock (Generic)
    deriving anyclass (Beamable)
  primaryKey = SymbolBuildKey . (.id)

data SymbolKindT f = SymbolKind
  { buildId :: C f Int32
  , kind :: C f T.Text
  , directory :: C f T.Text
  , files :: C f Int32
  }
  deriving stock (Generic)
  deriving anyclass (Beamable)

instance Table SymbolKindT where
  data PrimaryKey SymbolKindT f = SymbolKindKey (C f Int32) (C f T.Text)
    deriving stock (Generic)
    deriving anyclass (Beamable)
  primaryKey row = SymbolKindKey row.buildId row.kind

data SymbolEntryT f = SymbolEntry
  { buildId :: C f Int32
  , kind :: C f T.Text
  , identifier :: C f T.Text
  , path :: C f T.Text
  }
  deriving stock (Generic)
  deriving anyclass (Beamable)

instance Table SymbolEntryT where
  data PrimaryKey SymbolEntryT f = SymbolEntryKey (C f Int32) (C f T.Text) (C f T.Text)
    deriving stock (Generic)
    deriving anyclass (Beamable)
  primaryKey row = SymbolEntryKey row.buildId row.kind row.identifier

data InsightsDb f = InsightsDb
  { project :: f (TableEntity ProjectT)
  , person :: f (TableEntity PersonT)
  , device :: f (TableEntity DeviceT)
  , ingested :: f (TableEntity IngestedT)
  , event :: f (TableEntity EventT)
  , session :: f (TableEntity SessionT)
  , issue :: f (TableEntity IssueT)
  , crash :: f (TableEntity CrashT)
  , consent :: f (TableEntity ConsentT)
  , erasure :: f (TableEntity ErasureT)
  , symbolBuild :: f (TableEntity SymbolBuildT)
  , symbolKind :: f (TableEntity SymbolKindT)
  , symbolEntry :: f (TableEntity SymbolEntryT)
  }
  deriving stock (Generic)
  deriving anyclass (Database be)

insightsDb :: DatabaseSettings be InsightsDb
insightsDb =
  withDbModification
    (withDbModification defaultDbSettings (renamingFields (\(name :| _) -> snake name)))
    dbModification
      { symbolBuild = setEntityName "symbol_build"
      , symbolKind = setEntityName "symbol_kind"
      , symbolEntry = setEntityName "symbol_entry"
      }

snake :: T.Text -> T.Text
snake = T.concatMap \c -> if isUpper c then T.pack ['_', toLower c] else T.singleton c
