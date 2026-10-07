{-# LANGUAGE TemplateHaskell #-}

module Test.Peculiar.Insights.Server.Dashboards
  ( tests
  ) where

import Control.Exception (bracket, try)
import Control.Monad (void)
import Control.Monad.IO.Class (liftIO)
import Data.Aeson (eitherDecodeStrict)
import Data.ByteString qualified as B
import Data.FileEmbed (embedDir)
import Data.List (findIndex, sortOn)
import Data.Map.Strict qualified as Map
import Data.Maybe (catMaybes, fromMaybe, mapMaybe)
import Data.String (fromString)
import Data.Text qualified as T
import Data.Text.Encoding qualified as TE
import Data.Time (UTCTime (..), addUTCTime, fromGregorian, getCurrentTime, nominalDay)
import Database.PostgreSQL.Simple (Connection, SqlError (..), close, connectPostgreSQL, execute_, query_)
import Database.PostgreSQL.Simple.FromField (FromField (..), name)
import Hedgehog
import Peculiar.Insights.Server.Db (Db (..), describeDbError, withDb)
import Peculiar.Insights.Server.Maintain (analyticsStatements, cohortStatements)
import Test.Peculiar.Insights.Server.Dashboard
import Test.Peculiar.Insights.Server.Db (crashItem, eventItem, project)

data Site
  = Whole
  | AtVariable T.Text
  | AtQuery PanelQuery
  deriving stock (Eq, Show)

data Problem
  = Undecodable T.Text
  | Unresolvable Unresolved
  | Refused T.Text
  | NoValues
  deriving stock (Eq, Show)

data Failure = Failure
  { dashboard :: FilePath
  , site :: Site
  , problem :: Problem
  }
  deriving stock (Eq, Show)

describe :: Failure -> T.Text
describe found = T.pack found.dashboard <> where_ found.site <> ": " <> what found.problem
 where
  where_ = \case
    Whole -> ""
    AtVariable variable -> ", variable " <> variable
    AtQuery PanelQuery{panel, target} -> ", panel " <> T.pack (show panel.id) <> " \"" <> panel.title <> "\" query " <> target.refId
  what = \case
    Undecodable reason -> "not a dashboard: " <> reason
    Unresolvable unresolved -> describeUnresolved unresolved
    Refused reason -> "PostgreSQL refused it: " <> reason
    NoValues -> "the query listed no values"

data Cell = Cell
  { column :: Maybe B.ByteString
  , value :: Maybe B.ByteString
  }

instance FromField Cell where
  fromField field value = pure Cell{column = name field, value}

dashboards :: [(FilePath, B.ByteString)]
dashboards = sortOn fst $(embedDir "../../grafana/dashboards")

tests :: T.Text -> IO Group
tests conninfo = do
  seeded <- seed conninfo
  now <- getCurrentTime
  let range = TimeRange{from = addUTCTime (-(7 * nominalDay)) now, to = now}
  pure
    ( Group
        "Dashboards"
        [ ("every panel and variable query of every dashboard runs against the migrations", withTests 1 (shipped seeded range))
        , ("a query naming a column the migrations do not create fails on its dashboard and panel", withTests 1 (ghost seeded range))
        , ("single values are escaped, lists are quoted, raw values are left alone", withTests 1 formats)
        , ("time macros expand to the range and the interval", withTests 1 macros)
        , ("an unknown variable is refused rather than sent", withTests 1 unknown)
        ]
    )

seed :: T.Text -> IO T.Text
seed conninfo = do
  connected conninfo \connection -> void (execute_ connection "CREATE DATABASE dashboards")
  let seeded = conninfo <> " dbname=dashboards"
  withDb seeded \db -> do
    now <- getCurrentTime
    let earlier = addUTCTime (-3600) now
    outcome <- runSteps db now earlier
    either (ioError . userError . T.unpack . describeDbError) pure outcome
  pure seeded
 where
  runSteps db now earlier = do
    migrated <- db.migrateSchema
    case migrated of
      Left refused -> pure (Left refused)
      Right () ->
        db.registerProjects [project] >>= \case
          Left refused -> pure (Left refused)
          Right registered -> do
            installed <- db.execute (cohortStatements registered <> analyticsStatements registered)
            case (installed, registered) of
              (Left refused, _) -> pure (Left refused)
              (Right (), one : _) ->
                void
                  <$> db.publish
                    one
                    now
                    [ eventItem (1, 1) earlier "phone-a" "view" (Just "ana")
                    , eventItem (1, 2) earlier "phone-a" "buy" (Just "ana")
                    , crashItem 1 3 earlier "phone-a"
                    ]
                    Map.empty
              (Right (), []) -> pure (Right ())

connected :: T.Text -> (Connection -> IO a) -> IO a
connected conninfo = bracket (connectPostgreSQL (TE.encodeUtf8 conninfo)) close

shipped :: T.Text -> TimeRange -> Property
shipped seeded range = property do
  failures <- liftIO (connected seeded \connection -> concat <$> traverse (checkFile connection range) dashboards)
  length dashboards === 8
  fmap describe failures === []

ghost :: T.Text -> TimeRange -> Property
ghost seeded range = property do
  let projectVariable = Variable{name = "project", kind = Query, query = "SELECT DISTINCT project FROM reporting.device ORDER BY 1", current = Nothing, multi = Just False, includeAll = Just False}
      haunted = Panel{id = 7, title = "Ghost column", targets = Just [Target{refId = "A", rawSql = "SELECT no_such_column FROM reporting.event WHERE project = '${project}' AND $__timeFilter(time)"}], panels = Nothing}
      fine = Panel{id = 8, title = "Events", targets = Just [Target{refId = "A", rawSql = "SELECT count(*) FROM reporting.event WHERE project = '${project}'"}], panels = Nothing}
      broken = Dashboard{title = "Broken", templating = Templating{list = [projectVariable]}, panels = [fine, haunted]}
  failures <- liftIO (connected seeded \connection -> checkDashboard connection range "broken.json" broken)
  fmap describe failures === ["broken.json, panel 7 \"Ghost column\" query A: PostgreSQL refused it: column \"no_such_column\" does not exist"]

bindings :: [(T.Text, Binding)] -> Bindings
bindings variables =
  Bindings
    { range = TimeRange{from = UTCTime (fromGregorian 2026 1 1) 0, to = UTCTime (fromGregorian 2026 1 8) 0}
    , intervalSeconds = 3600
    , variables = Map.fromList variables
    }

formats :: Property
formats = property do
  let bound = bindings [("project", Binding{values = ["o'hara"], multiple = False}), ("event", Binding{values = ["view", "b'uy"], multiple = True}), ("cohort", Binding{values = ["person_id IN (SELECT 1)"], multiple = False})]
  interpolate bound "p = '${project}' AND $project = x AND n IN (${event:sqlstring}) AND m IN ($event) AND ${cohort:raw}"
    === Right "p = 'o''hara' AND o''hara = x AND n IN ('view','b''uy') AND m IN ('view','b''uy') AND person_id IN (SELECT 1)"

macros :: Property
macros = property do
  interpolate (bindings []) "SELECT $__timeGroupAlias(time, $__interval), 1 WHERE $__timeFilter(time) AND f($__timeFrom(), $__timeTo()) AND 5 = $5"
    === Right "SELECT floor(extract(epoch from time)/3600)*3600 AS \"time\", 1 WHERE time BETWEEN '2026-01-01T00:00:00Z' AND '2026-01-08T00:00:00Z' AND f('2026-01-01T00:00:00Z', '2026-01-08T00:00:00Z') AND 5 = $5"

unknown :: Property
unknown = property do
  interpolate (bindings []) "WHERE project = '${projct}'" === Left (UnknownVariable "projct")
  interpolate (bindings []) "WHERE $__timeFiltr(time)" === Left (UnknownMacro "timeFiltr")

checkFile :: Connection -> TimeRange -> (FilePath, B.ByteString) -> IO [Failure]
checkFile connection range (file, contents) = case eitherDecodeStrict contents of
  Left reason -> pure [Failure{dashboard = file, site = Whole, problem = Undecodable (T.pack reason)}]
  Right dashboard -> checkDashboard connection range file dashboard

checkDashboard :: Connection -> TimeRange -> FilePath -> Dashboard -> IO [Failure]
checkDashboard connection range file dashboard = do
  resolved <- resolveAll Bindings{range, intervalSeconds = 3600, variables = Map.empty} dashboard.templating.list
  case resolved of
    Left stopped -> pure [stopped]
    Right bound -> catMaybes <$> traverse (runQuery bound) (panelQueries dashboard)
 where
  failing site problem = Failure{dashboard = file, site, problem}
  resolveAll bound = \case
    [] -> pure (Right bound)
    variable : rest ->
      resolve bound variable >>= \case
        Left problem -> pure (Left (failing (AtVariable variable.name) problem))
        Right [] -> pure (Left (failing (AtVariable variable.name) NoValues))
        Right values ->
          let multiple = Just True == variable.multi || Just True == variable.includeAll
              binding = Binding{values = if multiple then values else take 1 values, multiple}
           in resolveAll bound{variables = Map.insert variable.name binding bound.variables} rest
  resolve bound variable = case variable.kind of
    Textbox -> pure (Right [fromMaybe variable.query (variable.current >>= (.value))])
    Custom -> pure (Right (maybe (T.splitOn "," variable.query) pure (variable.current >>= (.value))))
    Query -> case interpolate bound variable.query of
      Left unresolved -> pure (Left (Unresolvable unresolved))
      Right sql -> fmap (mapMaybe listed) <$> rows connection sql
  runQuery bound query = case interpolate bound query.target.rawSql of
    Left unresolved -> pure (Just (failing (AtQuery query) (Unresolvable unresolved)))
    Right sql -> either (Just . failing (AtQuery query)) (const Nothing) <$> rows connection sql

listed :: [Cell] -> Maybe T.Text
listed cells =
  let chosen = maybe (take 1 cells) (\at -> take 1 (drop at cells)) (findIndex (\cell -> cell.column == Just "__value") cells)
   in case chosen of
        [Cell{value = Just bytes}] -> Just (TE.decodeUtf8 bytes)
        _ -> Nothing

rows :: Connection -> T.Text -> IO (Either Problem [[Cell]])
rows connection sql = do
  outcome <- try @SqlError (query_ connection (fromString (T.unpack sql)))
  pure case outcome of
    Left refused -> Left (Refused (TE.decodeUtf8 refused.sqlErrorMsg))
    Right found -> Right found
