module Test.Peculiar.Insights.Core.Metrics (tests) where

import Data.Text qualified as T
import Hedgehog
import Peculiar.Insights.Core.Metrics

tests :: Group
tests =
  Group
    "Metrics"
    [ ("the exposition of a registry", withTests 1 golden)
    , ("labels in any order are one series", withTests 1 unordered)
    , ("an empty registry renders nothing", withTests 1 nothing)
    ]

golden :: Property
golden = property do
  let registry =
        put (Series "insights_projects" []) 2
          . add (Series "insights_items_total" [("project", "shop"), ("environment", "prod"), ("outcome", "accepted")]) 3
          . add (Series "insights_items_total" [("project", "shop"), ("environment", "prod"), ("outcome", "accepted")]) 4
          . add (Series "insights_items_total" [("project", "sh\"op"), ("environment", "prod"), ("outcome", "invalid")]) 1
          . add (Series "insights_request_seconds_total" [("method", "Publish")]) 0.25
          $ emptyRegistry
  render descriptors registry
    === T.unlines
      [ "# HELP insights_request_seconds_total Seconds spent answering calls, by method."
      , "# TYPE insights_request_seconds_total counter"
      , "insights_request_seconds_total{method=\"Publish\"} 0.25"
      , "# HELP insights_items_total Items received in batches, by project, environment and outcome."
      , "# TYPE insights_items_total counter"
      , "insights_items_total{environment=\"prod\",outcome=\"accepted\",project=\"shop\"} 7"
      , "insights_items_total{environment=\"prod\",outcome=\"invalid\",project=\"sh\\\"op\"} 1"
      , "# HELP insights_projects Environments the server accepts data for."
      , "# TYPE insights_projects gauge"
      , "insights_projects 2"
      ]

unordered :: Property
unordered = property do
  let one = add (Series "insights_requests_total" [("method", "Publish"), ("code", "ok")]) 1 emptyRegistry
      both = add (Series "insights_requests_total" [("code", "ok"), ("method", "Publish")]) 1 one
  render descriptors both
    === T.unlines
      [ "# HELP insights_requests_total Calls answered, by method and gRPC status code."
      , "# TYPE insights_requests_total counter"
      , "insights_requests_total{code=\"ok\",method=\"Publish\"} 2"
      ]

nothing :: Property
nothing = property (render descriptors emptyRegistry === "")
