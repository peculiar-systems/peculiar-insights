module Peculiar.Insights.Core.Config
  ( Config (..)
  , Listen (..)
  , TlsFiles (..)
  , Monitoring (..)
  , Grafana (..)
  , Rate (..)
  , PeerLimit (..)
  , Project (..)
  , Symbols (..)
  , UploadKey (..)
  , Cohort (..)
  , Analytics (..)
  , emptyAnalytics
  , Funnel (..)
  , Step (..)
  , Matcher (..)
  , Retention (..)
  , Period (..)
  , periodName
  , Metric (..)
  , Measure (..)
  , Aggregate (..)
  , Condition (..)
  , PropertyCondition (..)
  , EventCondition (..)
  , AbsenceCondition (..)
  , ConfigError (..)
  , checkConfig
  , describeConfigError
  ) where

import Data.Aeson (FromJSON, ToJSON)
import Data.Aeson qualified as Aeson
import Data.Char (isAsciiLower, isDigit)
import Data.Foldable (traverse_)
import Data.List (sortOn)
import Data.Map.Strict qualified as Map
import Data.Maybe (fromMaybe)
import Data.Set qualified as Set
import Data.Text qualified as T
import Deriving.Aeson (CamelToSnake, ConstructorTagModifier, CustomJSON (..), FieldLabelModifier, SumObjectWithSingleField)
import GHC.Generics (Generic)

type Snake = CustomJSON '[FieldLabelModifier '[CamelToSnake]]

data Config = Config
  { listen :: Listen
  , monitoring :: Maybe Monitoring
  , peerLimit :: Maybe PeerLimit
  , database :: T.Text
  , reportingRole :: Maybe T.Text
  , grafana :: Maybe Grafana
  , symbols :: Symbols
  , projects :: [Project]
  }
  deriving stock (Eq, Show, Generic)
  deriving (FromJSON, ToJSON) via Snake Config

data Symbols = Symbols
  { directory :: FilePath
  , maxUploadBytes :: Int
  , uploadKeys :: [UploadKey]
  }
  deriving stock (Eq, Show, Generic)
  deriving (FromJSON, ToJSON) via Snake Symbols

data UploadKey = UploadKey
  { project :: T.Text
  , keyFile :: FilePath
  }
  deriving stock (Eq, Show, Generic)
  deriving (FromJSON, ToJSON) via Snake UploadKey

data Grafana = Grafana
  { url :: T.Text
  , organization :: Int
  }
  deriving stock (Eq, Show, Generic)
  deriving (FromJSON, ToJSON) via Snake Grafana

data Monitoring = Monitoring
  { host :: T.Text
  , port :: Int
  }
  deriving stock (Eq, Show, Generic)
  deriving (FromJSON, ToJSON) via Snake Monitoring

data Rate = Rate
  { perMinute :: Int
  , burst :: Int
  }
  deriving stock (Eq, Show, Generic)
  deriving (FromJSON, ToJSON) via Snake Rate

data PeerLimit = PeerLimit
  { rate :: Rate
  , forwardedHeader :: Maybe T.Text
  }
  deriving stock (Eq, Show, Generic)
  deriving (FromJSON, ToJSON) via Snake PeerLimit

data Listen = Listen
  { host :: T.Text
  , port :: Int
  , tls :: Maybe TlsFiles
  , corsOrigins :: [T.Text]
  }
  deriving stock (Eq, Show, Generic)
  deriving (FromJSON, ToJSON) via Snake Listen

data TlsFiles = TlsFiles
  { certificate :: FilePath
  , key :: FilePath
  }
  deriving stock (Eq, Show, Generic)
  deriving (FromJSON, ToJSON) via Snake TlsFiles

data Project = Project
  { slug :: T.Text
  , environment :: T.Text
  , keyFile :: FilePath
  , retentionDays :: Maybe Int
  , rateLimit :: Maybe Rate
  , denylist :: [T.Text]
  , cohorts :: [Cohort]
  , analytics :: Maybe Analytics
  }
  deriving stock (Eq, Show, Generic)
  deriving (FromJSON, ToJSON) via Snake Project

data Analytics = Analytics
  { funnels :: [Funnel]
  , retention :: [Retention]
  , metrics :: [Metric]
  }
  deriving stock (Eq, Show, Generic)
  deriving (FromJSON, ToJSON) via Snake Analytics

emptyAnalytics :: Analytics
emptyAnalytics = Analytics{funnels = [], retention = [], metrics = []}

data Matcher = Matcher
  { event :: T.Text
  , filters :: Map.Map T.Text Aeson.Value
  }
  deriving stock (Eq, Show, Generic)
  deriving (FromJSON, ToJSON) via Snake Matcher

data Step = Step
  { label :: T.Text
  , event :: T.Text
  , filters :: Map.Map T.Text Aeson.Value
  }
  deriving stock (Eq, Show, Generic)
  deriving (FromJSON, ToJSON) via Snake Step

data Funnel = Funnel
  { name :: T.Text
  , steps :: [Step]
  , windowDays :: Int
  , lookbackDays :: Int
  }
  deriving stock (Eq, Show, Generic)
  deriving (FromJSON, ToJSON) via Snake Funnel

data Period = Day | Week | Month
  deriving stock (Eq, Show, Enum, Bounded, Generic)
  deriving (FromJSON, ToJSON) via CustomJSON '[ConstructorTagModifier '[CamelToSnake]] Period

periodName :: Period -> T.Text
periodName = \case
  Day -> "day"
  Week -> "week"
  Month -> "month"

data Retention = Retention
  { name :: T.Text
  , birth :: Matcher
  , returnEvent :: Matcher
  , period :: Period
  , periods :: Int
  , lookbackDays :: Int
  }
  deriving stock (Eq, Show, Generic)
  deriving (FromJSON, ToJSON) via Snake Retention

data Aggregate = Sum | Average | Minimum | Maximum | Median | P95 | P99
  deriving stock (Eq, Show, Enum, Bounded, Generic)
  deriving (FromJSON, ToJSON) via CustomJSON '[ConstructorTagModifier '[CamelToSnake]] Aggregate

data Measure = Measure
  { property :: T.Text
  , aggregate :: Aggregate
  }
  deriving stock (Eq, Show, Generic)
  deriving (FromJSON, ToJSON) via Snake Measure

data Metric = Metric
  { name :: T.Text
  , event :: T.Text
  , filters :: Map.Map T.Text Aeson.Value
  , measure :: Maybe Measure
  }
  deriving stock (Eq, Show, Generic)
  deriving (FromJSON, ToJSON) via Snake Metric

data Cohort = Cohort
  { name :: T.Text
  , conditions :: [Condition]
  }
  deriving stock (Eq, Show, Generic)
  deriving (FromJSON, ToJSON) via Snake Cohort

data Condition
  = PersonProperty PropertyCondition
  | DidEvent EventCondition
  | DidNotEvent AbsenceCondition
  deriving stock (Eq, Show, Generic)
  deriving
    (FromJSON, ToJSON)
    via CustomJSON '[SumObjectWithSingleField, ConstructorTagModifier '[CamelToSnake]] Condition

data PropertyCondition = PropertyCondition
  { key :: T.Text
  , equals :: Aeson.Value
  }
  deriving stock (Eq, Show, Generic)
  deriving (FromJSON, ToJSON) via Snake PropertyCondition

data EventCondition = EventCondition
  { event :: T.Text
  , filters :: Map.Map T.Text Aeson.Value
  , atLeast :: Int
  , withinDays :: Int
  }
  deriving stock (Eq, Show, Generic)
  deriving (FromJSON, ToJSON) via Snake EventCondition

data AbsenceCondition = AbsenceCondition
  { event :: T.Text
  , filters :: Map.Map T.Text Aeson.Value
  , withinDays :: Int
  }
  deriving stock (Eq, Show, Generic)
  deriving (FromJSON, ToJSON) via Snake AbsenceCondition

data ConfigError
  = BadIdentifier T.Text
  | DuplicateProject T.Text T.Text
  | DuplicateCohort T.Text T.Text
  | DuplicateAnalytics T.Text T.Text
  | FunnelTooShort T.Text
  | FunnelTooLong T.Text
  | Unnamed T.Text
  | NotPositive T.Text
  | NoProjects
  | BadRetention T.Text Int
  | BadPort Int
  | UnknownUploadProject T.Text
  | DuplicateUploadKey T.Text
  deriving stock (Eq, Show)

describeConfigError :: ConfigError -> T.Text
describeConfigError = \case
  BadIdentifier name -> "identifier " <> name <> " must be lowercase ascii letters, digits and underscores, starting with a letter"
  DuplicateProject slug environment -> "project " <> slug <> "/" <> environment <> " is declared twice"
  DuplicateCohort project name -> "cohort " <> name <> " of project " <> project <> " is declared twice"
  DuplicateAnalytics project name -> "analytics " <> name <> " of project " <> project <> " is declared twice"
  FunnelTooShort name -> "funnel " <> name <> " needs at least two steps"
  FunnelTooLong name -> "funnel " <> name <> " has more than " <> T.pack (show maxSteps) <> " steps"
  Unnamed what -> what <> " names no event or property"
  NotPositive name -> name <> " must be positive"
  NoProjects -> "no projects are declared"
  BadRetention project days -> "project " <> project <> " has a retention of " <> T.pack (show days) <> " days, which is not positive"
  BadPort port -> "port " <> T.pack (show port) <> " is out of range"
  UnknownUploadProject project -> "an upload key names project " <> project <> ", which is not declared"
  DuplicateUploadKey project -> "project " <> project <> " has two upload keys"

maxSteps :: Int
maxSteps = 60

checkConfig :: Config -> Either ConfigError ()
checkConfig config = do
  traverse_ checkPort (config.listen.port : [monitoring.port | Just monitoring <- [config.monitoring]])
  traverse_ (checkRate "the peer limit" . (.rate)) config.peerLimit
  if null config.projects then Left NoProjects else Right ()
  traverse_ checkIdentifier config.reportingRole
  traverse_ (\grafana -> if grafana.organization > 0 then Right () else Left (NotPositive "the Grafana organization")) config.grafana
  traverse_ checkProject config.projects
  unique (\project -> DuplicateProject project.slug project.environment) (\project -> (project.slug, project.environment)) config.projects
  checkSymbols (Set.fromList (fmap (.slug) config.projects)) config.symbols

checkSymbols :: Set.Set T.Text -> Symbols -> Either ConfigError ()
checkSymbols declared symbols = do
  if symbols.maxUploadBytes > 0 then Right () else Left (NotPositive "the symbols upload cap")
  traverse_ (\key -> if Set.member key.project declared then Right () else Left (UnknownUploadProject key.project)) symbols.uploadKeys
  unique (DuplicateUploadKey . (.project)) (.project) symbols.uploadKeys

checkPort :: Int -> Either ConfigError ()
checkPort port = if port > 0 && port < 65536 then Right () else Left (BadPort port)

checkRate :: T.Text -> Rate -> Either ConfigError ()
checkRate what rate = do
  if rate.perMinute > 0 then Right () else Left (NotPositive (what <> " per minute"))
  if rate.burst > 0 then Right () else Left (NotPositive (what <> " burst"))

named :: T.Text -> T.Text -> Either ConfigError ()
named what name = if T.null (T.strip name) then Left (Unnamed what) else Right ()

checkProject :: Project -> Either ConfigError ()
checkProject project = do
  traverse_ checkIdentifier [project.slug, project.environment]
  traverse_ (checkRate (project.slug <> "/" <> project.environment <> " rate limit")) project.rateLimit
  traverse_ (\cohort -> checkIdentifier cohort.name) project.cohorts
  traverse_ checkCohort project.cohorts
  case project.retentionDays of
    Just days | days <= 0 -> Left (BadRetention project.slug days)
    _ -> Right ()
  unique (DuplicateCohort project.slug . (.name)) (.name) project.cohorts
  checkAnalytics project.slug (fromMaybe emptyAnalytics project.analytics)

checkAnalytics :: T.Text -> Analytics -> Either ConfigError ()
checkAnalytics slug analytics = do
  traverse_ checkIdentifier (fmap (.name) analytics.funnels <> fmap (.name) analytics.retention <> fmap (.name) analytics.metrics)
  unique (DuplicateAnalytics slug . (.name)) (.name) analytics.funnels
  unique (DuplicateAnalytics slug . (.name)) (.name) analytics.retention
  unique (DuplicateAnalytics slug . (.name)) (.name) analytics.metrics
  traverse_ checkFunnel analytics.funnels
  traverse_ checkRetention analytics.retention
  traverse_ checkMetric analytics.metrics
 where
  checkFunnel funnel = do
    if length funnel.steps < 2 then Left (FunnelTooShort funnel.name) else Right ()
    if length funnel.steps > maxSteps then Left (FunnelTooLong funnel.name) else Right ()
    traverse_ (\step -> named ("a step of funnel " <> funnel.name) step.event) funnel.steps
    positive (funnel.name <> " window") funnel.windowDays
    positive (funnel.name <> " lookback") funnel.lookbackDays
  checkRetention retention = do
    named ("the birth of retention " <> retention.name) retention.birth.event
    named ("the return of retention " <> retention.name) retention.returnEvent.event
    positive (retention.name <> " periods") retention.periods
    positive (retention.name <> " lookback") retention.lookbackDays
  checkMetric metric = do
    named ("metric " <> metric.name) metric.event
    traverse_ (\measure -> named ("the measure of metric " <> metric.name) measure.property) metric.measure
  positive what n = if n > 0 then Right () else Left (NotPositive what)

checkCohort :: Cohort -> Either ConfigError ()
checkCohort cohort = traverse_ condition cohort.conditions
 where
  condition = \case
    PersonProperty property -> named ("a property of cohort " <> cohort.name) property.key
    DidEvent occurrence -> named ("an event of cohort " <> cohort.name) occurrence.event
    DidNotEvent absence -> named ("an event of cohort " <> cohort.name) absence.event

checkIdentifier :: T.Text -> Either ConfigError ()
checkIdentifier name = case T.uncons name of
  Just (first, rest)
    | isAsciiLower first
    , T.all (\c -> isAsciiLower c || isDigit c || c == '_') rest
    , T.length name <= 48 ->
        Right ()
  _ -> Left (BadIdentifier name)

unique :: (Ord key) => (a -> ConfigError) -> (a -> key) -> [a] -> Either ConfigError ()
unique failure key items = go Set.empty (sortOn key items)
 where
  go _ [] = Right ()
  go seen (item : rest)
    | Set.member (key item) seen = Left (failure item)
    | otherwise = go (Set.insert (key item) seen) rest
