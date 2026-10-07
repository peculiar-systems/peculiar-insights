module Test.Peculiar.Insights.Server.Analysis
  ( tests
  ) where

import Control.Exception (bracket)
import Control.Monad.IO.Class (liftIO)
import Data.Aeson qualified as Aeson
import Data.Int (Int64)
import Data.Map.Strict qualified as Map
import Data.String (fromString)
import Data.Text qualified as T
import Data.Text.Encoding qualified as TE
import Data.Time (UTCTime, addUTCTime, getCurrentTime)
import Data.Word (Word32)
import Database.PostgreSQL.Simple (Only (..), close, connectPostgreSQL, query_)
import Hedgehog
import Peculiar.Insights.Core.Config (Aggregate (..), Analytics (..), Cohort (..), Condition (..), EventCondition (..), Funnel (..), Matcher (..), Measure (..), Metric (..), Project (..), Retention (..), Step (..))
import Peculiar.Insights.Core.Config qualified as Config
import Peculiar.Insights.Core.Item
import Peculiar.Insights.Core.Value (Value (..))
import Peculiar.Insights.Server.Db (Db (..), DbError (..))
import Peculiar.Insights.Server.Maintain (analyticsStatements, cohortStatements, staleStatements)
import Peculiar.Insights.Server.Projects (Registered (..))
import Test.Peculiar.Insights.Server.Db (itemIdOf, sampleContext)

tests :: T.Text -> Db -> Group
tests conninfo db =
  Group
    "Analysis"
    [ ("declared steps, measures, returns and conditions match on properties", withTests 1 (matching conninfo db))
    , ("a view no longer declared is dropped", withTests 1 (dropped conninfo db))
    ]

on :: T.Text -> Map.Map T.Text Aeson.Value
on channel = Map.fromList [("channel", Aeson.toJSON channel)]

studio :: Project
studio =
  Project
    { slug = "studio"
    , environment = "test"
    , keyFile = ""
    , retentionDays = Nothing
    , rateLimit = Nothing
    , denylist = []
    , cohorts = [Cohort{name = "web_buyers", conditions = [DidEvent EventCondition{event = "buy", filters = on "web", atLeast = 1, withinDays = 30}]}]
    , analytics =
        Just
          Analytics
            { funnels =
                [ Funnel
                    { name = "web"
                    , steps = [Step{label = "saw it", event = "view", filters = Map.empty}, Step{label = "bought on the web", event = "buy", filters = on "web"}]
                    , windowDays = 7
                    , lookbackDays = 30
                    }
                ]
            , retention =
                [ Retention
                    { name = "web"
                    , birth = Matcher{event = "view", filters = Map.empty}
                    , returnEvent = Matcher{event = "buy", filters = on "web"}
                    , period = Config.Day
                    , periods = 1
                    , lookbackDays = 30
                    }
                ]
            , metrics =
                [ Metric{name = "revenue", event = "buy", filters = Map.empty, measure = Just Measure{property = "total", aggregate = Sum}}
                , Metric{name = "largest", event = "buy", filters = on "web", measure = Just Measure{property = "total", aggregate = Maximum}}
                , Metric{name = "orders", event = "buy", filters = Map.empty, measure = Nothing}
                ]
            }
    }

happened :: Word32 -> UTCTime -> T.Text -> T.Text -> [(T.Text, Value)] -> Item
happened n at user name properties =
  ItemEvent
    Event
      { id = itemIdOf 40 n
      , time = at
      , subject = Subject{device = DeviceId (user <> "-phone"), user = Just (UserId user), session = SessionId (user <> "-s")}
      , context = sampleContext
      , name
      , properties = Map.fromList properties
      }

asking :: T.Text -> T.Text -> IO [[Maybe Double]]
asking conninfo sql = bracket (connectPostgreSQL (TE.encodeUtf8 conninfo)) close \connection ->
  query_ connection (fromString (T.unpack sql))

installed :: Db -> Project -> IO (Either DbError Registered)
installed db declared =
  db.registerProjects [declared] >>= \case
    Right [registered] -> fmap (const registered) <$> db.execute (staleStatements [registered] <> cohortStatements [registered] <> analyticsStatements [registered])
    Right _ -> pure (Left (Unavailable "registering the project gave more than one"))
    Left refused -> pure (Left refused)

matching :: T.Text -> Db -> Property
matching conninfo db = property do
  now <- liftIO getCurrentTime
  let earlier = addUTCTime (-60) now
  registered <- evalEither =<< liftIO (installed db studio)
  stored <-
    liftIO
      ( db.publish
          registered
          now
          [ happened 1 earlier "ana" "view" []
          , happened 2 now "ana" "buy" [("channel", VString "web"), ("total", VDouble 12.5)]
          , happened 3 earlier "ben" "view" []
          , happened 4 now "ben" "buy" [("channel", VString "app"), ("total", VInt 30)]
          , happened 5 now "ben" "buy" [("channel", VString "app"), ("total", VString "a lot")]
          ]
          Map.empty
      )
  fmap length stored === Right 5
  funnel <- liftIO (asking conninfo "SELECT step::double precision, people::double precision FROM reporting.funnel_studio_test_web ORDER BY step")
  funnel === [[Just 1, Just 2], [Just 2, Just 1]]
  labels <- liftIO (bracket (connectPostgreSQL (TE.encodeUtf8 conninfo)) close (`query_` "SELECT name FROM reporting.funnel_studio_test_web ORDER BY step"))
  labels === [Only ("saw it" :: T.Text), Only "bought on the web"]
  revenue <- liftIO (asking conninfo "SELECT events::double precision, value FROM reporting.metric_studio_test_revenue")
  revenue === [[Just 3, Just 42.5]]
  largest <- liftIO (asking conninfo "SELECT events::double precision, value FROM reporting.metric_studio_test_largest")
  largest === [[Just 1, Just 12.5]]
  orders <- liftIO (asking conninfo "SELECT events::double precision, value FROM reporting.metric_studio_test_orders")
  orders === [[Just 3, Nothing]]
  retained <- liftIO (asking conninfo "SELECT cohort_size::double precision, retained::double precision FROM reporting.retention_studio_test_web WHERE period = 0")
  retained === [[Just 2, Just 1]]
  buyers <- liftIO (asking conninfo "SELECT count(*)::double precision FROM reporting.cohort_studio_test_web_buyers")
  buyers === [[Just 1]]

dropped :: T.Text -> Db -> Property
dropped conninfo db = property do
  let views = "SELECT count(*)::double precision FROM pg_views WHERE schemaname = 'reporting' AND viewname IN ('metric_studio_test_largest', 'cohort_studio_test_web_buyers')"
  _ <- evalEither =<< liftIO (installed db studio)
  before <- liftIO (asking conninfo views)
  before === [[Just 2]]
  let fewer = studio{cohorts = [], analytics = fmap (\analytics -> analytics{metrics = take 1 analytics.metrics}) studio.analytics}
  _ <- evalEither =<< liftIO (installed db fewer)
  after <- liftIO (asking conninfo views)
  after === [[Just 0]]
  kept <- liftIO (asking conninfo "SELECT count(*)::double precision FROM pg_views WHERE schemaname = 'reporting' AND viewname IN ('metric_studio_test_revenue', 'event', 'crash_free_daily')")
  kept === [[Just 3]]
  (_ :: [Only Int64]) <- liftIO (bracket (connectPostgreSQL (TE.encodeUtf8 conninfo)) close (`query_` "SELECT count(*) FROM reporting.event"))
  success
