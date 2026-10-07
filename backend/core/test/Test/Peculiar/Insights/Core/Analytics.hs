module Test.Peculiar.Insights.Core.Analytics (tests) where

import Data.Aeson qualified as Aeson
import Data.Map.Strict qualified as Map
import Data.Text qualified as T
import Data.Text.Encoding qualified as TE
import Hedgehog
import Peculiar.Insights.Core.Analytics
import Peculiar.Insights.Core.Config
import Peculiar.Insights.Core.Enum (enumerate)

tests :: Group
tests =
  Group
    "Analytics"
    [ ("the module's project json decodes to the declared analytics", withTests 1 contract)
    , ("the views for a declared environment", withTests 1 golden)
    , ("every aggregate has its expression", withTests 1 aggregates)
    , ("views no longer declared are dropped, and declared ones named", withTests 1 stale)
    , ("a funnel with one step is rejected", withTests 1 tooShort)
    , ("a measure without a property is rejected", withTests 1 unnamed)
    , ("a rate that allows nothing is rejected", withTests 1 badRate)
    , ("a Grafana organization that is not positive is rejected", withTests 1 badOrganization)
    ]

project :: Project
project =
  Project
    { slug = "shop"
    , environment = "prod"
    , keyFile = "/run/key"
    , retentionDays = Nothing
    , rateLimit = Just Rate{perMinute = 6000, burst = 12000}
    , denylist = []
    , cohorts = []
    , analytics = Just declared
    }

web :: Map.Map T.Text Aeson.Value
web = Map.fromList [("source", Aeson.toJSON ("web" :: T.Text))]

declared :: Analytics
declared =
  Analytics
    { funnels =
        [ Funnel
            { name = "checkout"
            , steps = [Step{label = "a", event = "a", filters = Map.empty}, Step{label = "b on the web", event = "b", filters = web}]
            , windowDays = 7
            , lookbackDays = 90
            }
        ]
    , retention =
        [ Retention
            { name = "weekly"
            , birth = Matcher{event = "scan_completed", filters = Map.empty}
            , returnEvent = Matcher{event = "scan_completed", filters = web}
            , period = Week
            , periods = 8
            , lookbackDays = 180
            }
        ]
    , metrics =
        [ Metric{name = "scans", event = "scan_completed", filters = web, measure = Nothing}
        , Metric{name = "revenue", event = "order_placed", filters = Map.empty, measure = Just Measure{property = "total", aggregate = Sum}}
        ]
    }

config :: [Project] -> Config
config projects =
  Config
    { listen = Listen{host = "127.0.0.1", port = 50051, tls = Nothing, corsOrigins = []}
    , monitoring = Just Monitoring{host = "127.0.0.1", port = 9464}
    , peerLimit = Just PeerLimit{rate = Rate{perMinute = 600, burst = 1200}, forwardedHeader = Nothing}
    , database = ""
    , reportingRole = Nothing
    , grafana = Just Grafana{url = "http://127.0.0.1:3000", organization = 1}
    , symbols = Symbols{directory = "/var/lib/insights/symbols", maxUploadBytes = 1024, uploadKeys = []}
    , projects
    }

contract :: Property
contract = property do
  let json =
        "{\"slug\":\"shop\",\"environment\":\"prod\",\"key_file\":\"/run/key\",\"retention_days\":null,\"rate_limit\":{\"per_minute\":6000,\"burst\":12000},\"denylist\":[],\"cohorts\":[],"
          <> "\"analytics\":{\"funnels\":[{\"name\":\"checkout\",\"steps\":[{\"label\":\"a\",\"event\":\"a\",\"filters\":{}},{\"label\":\"b on the web\",\"event\":\"b\",\"filters\":{\"source\":\"web\"}}],\"window_days\":7,\"lookback_days\":90}],"
          <> "\"retention\":[{\"name\":\"weekly\",\"birth\":{\"event\":\"scan_completed\",\"filters\":{}},\"return_event\":{\"event\":\"scan_completed\",\"filters\":{\"source\":\"web\"}},\"period\":\"week\",\"periods\":8,\"lookback_days\":180}],"
          <> "\"metrics\":[{\"name\":\"scans\",\"event\":\"scan_completed\",\"filters\":{\"source\":\"web\"},\"measure\":null},"
          <> "{\"name\":\"revenue\",\"event\":\"order_placed\",\"filters\":{},\"measure\":{\"property\":\"total\",\"aggregate\":\"sum\"}}]}}"
  Aeson.eitherDecodeStrict (TE.encodeUtf8 json) === Right project
  checkConfig (config [project]) === Right ()

golden :: Property
golden = property do
  analyticsSql project declared
    === [ T.unlines
            [ "CREATE OR REPLACE VIEW reporting.funnel_shop_prod_checkout AS"
            , "SELECT step, name, people"
            , "FROM reporting.funnel_steps('shop', 'prod', '[{\"event\":\"a\",\"filters\":{},\"label\":\"a\"},{\"event\":\"b\",\"filters\":{\"source\":\"web\"},\"label\":\"b on the web\"}]'::jsonb, make_interval(days => 7), now() - make_interval(days => 90), now())"
            ]
        , T.unlines
            [ "CREATE OR REPLACE VIEW reporting.retention_shop_prod_weekly AS"
            , "SELECT cohort, period, cohort_size, retained"
            , "FROM reporting.retention_matching('shop', 'prod', '{\"event\":\"scan_completed\",\"filters\":{}}'::jsonb, '{\"event\":\"scan_completed\",\"filters\":{\"source\":\"web\"}}'::jsonb, 'week', now() - make_interval(days => 180), now(), 8)"
            ]
        , T.unlines
            [ "CREATE OR REPLACE VIEW reporting.metric_shop_prod_scans AS"
            , "SELECT date_trunc('day', event.time) AS day, count(*) AS events, count(DISTINCT COALESCE(event.person_id::text, 'd:' || event.device_id)) AS people, NULL::double precision AS value"
            , "FROM event"
            , "JOIN project ON project.id = event.project_id"
            , "WHERE project.slug = 'shop'"
            , "  AND project.environment = 'prod'"
            , "  AND event.name = 'scan_completed'"
            , "  AND event.properties @> '{\"source\":\"web\"}'::jsonb"
            , "GROUP BY 1"
            ]
        , T.unlines
            [ "CREATE OR REPLACE VIEW reporting.metric_shop_prod_revenue AS"
            , "SELECT date_trunc('day', event.time) AS day, count(*) AS events, count(DISTINCT COALESCE(event.person_id::text, 'd:' || event.device_id)) AS people, sum(CASE WHEN jsonb_typeof(event.properties -> 'total') = 'number' THEN (event.properties ->> 'total')::double precision END) AS value"
            , "FROM event"
            , "JOIN project ON project.id = event.project_id"
            , "WHERE project.slug = 'shop'"
            , "  AND project.environment = 'prod'"
            , "  AND event.name = 'order_placed'"
            , "GROUP BY 1"
            ]
        ]

aggregates :: Property
aggregates = property do
  let number = "CASE WHEN jsonb_typeof(p -> 'it''s') = 'number' THEN (p ->> 'it''s')::double precision END"
  fmap (\aggregate -> measured "p" Measure{property = "it's", aggregate}) enumerate
    === [ "sum(" <> number <> ")"
        , "avg(" <> number <> ")"
        , "min(" <> number <> ")"
        , "max(" <> number <> ")"
        , "percentile_cont(0.5) WITHIN GROUP (ORDER BY " <> number <> ")"
        , "percentile_cont(0.95) WITHIN GROUP (ORDER BY " <> number <> ")"
        , "percentile_cont(0.99) WITHIN GROUP (ORDER BY " <> number <> ")"
        ]

stale :: Property
stale = property do
  let buyers = Cohort{name = "buyers", conditions = []}
      named = project{cohorts = [buyers]}
  declaredViews named === ["cohort_shop_prod_buyers", "funnel_shop_prod_checkout", "retention_shop_prod_weekly", "metric_shop_prod_scans", "metric_shop_prod_revenue"]
  assert ("AND NOT (viewname = ANY (ARRAY['cohort_shop_prod_buyers', 'funnel_shop_prod_checkout', 'retention_shop_prod_weekly', 'metric_shop_prod_scans', 'metric_shop_prod_revenue']::text[]))" `T.isInfixOf` staleViews [named])
  assert ("ARRAY[]::text[]" `T.isInfixOf` staleViews [])

tooShort :: Property
tooShort = property do
  let short = declared{funnels = [Funnel{name = "one", steps = [Step{label = "a", event = "a", filters = Map.empty}], windowDays = 7, lookbackDays = 90}]}
  checkConfig (config [project{analytics = Just short}]) === Left (FunnelTooShort "one")

unnamed :: Property
unnamed = property do
  let blank = declared{metrics = [Metric{name = "revenue", event = "order_placed", filters = Map.empty, measure = Just Measure{property = " ", aggregate = Sum}}]}
  checkConfig (config [project{analytics = Just blank}]) === Left (Unnamed "the measure of metric revenue")

badRate :: Property
badRate = property do
  checkConfig (config [project{rateLimit = Just Rate{perMinute = 0, burst = 10}}]) === Left (NotPositive "shop/prod rate limit per minute")

badOrganization :: Property
badOrganization = property do
  checkConfig (config [project]){grafana = Just Grafana{url = "http://127.0.0.1:3000", organization = 0}} === Left (NotPositive "the Grafana organization")
