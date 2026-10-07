module Peculiar.Insights.Core.Analytics
  ( funnelView
  , retentionView
  , metricView
  , analyticsSql
  , measured
  , declaredViews
  , staleViews
  ) where

import Data.Aeson (ToJSON)
import Data.Aeson qualified as Aeson
import Data.Aeson.Text qualified as AesonText
import Data.Maybe (fromMaybe)
import Data.Text qualified as T
import Data.Text.Lazy qualified as TL
import Peculiar.Insights.Core.Cohort (quoteLiteral, viewName)
import Peculiar.Insights.Core.Config (Aggregate (..), Analytics (..), Funnel (..), Measure (..), Metric (..), Project (..), Retention (..), emptyAnalytics, periodName)

prefix :: Project -> T.Text -> T.Text -> T.Text
prefix project kind name = kind <> "_" <> project.slug <> "_" <> project.environment <> "_" <> name

scoped :: Project -> T.Text
scoped project = quoteLiteral project.slug <> ", " <> quoteLiteral project.environment

days :: Int -> T.Text
days n = "make_interval(days => " <> T.pack (show n) <> ")"

funnelView :: Project -> Funnel -> T.Text
funnelView project funnel =
  T.unlines
    [ "CREATE OR REPLACE VIEW reporting." <> prefix project "funnel" funnel.name <> " AS"
    , "SELECT step, name, people"
    , "FROM reporting.funnel_steps("
        <> scoped project
        <> ", "
        <> jsonb funnel.steps
        <> ", "
        <> days funnel.windowDays
        <> ", now() - "
        <> days funnel.lookbackDays
        <> ", now())"
    ]

retentionView :: Project -> Retention -> T.Text
retentionView project retention =
  T.unlines
    [ "CREATE OR REPLACE VIEW reporting." <> prefix project "retention" retention.name <> " AS"
    , "SELECT cohort, period, cohort_size, retained"
    , "FROM reporting.retention_matching("
        <> scoped project
        <> ", "
        <> jsonb retention.birth
        <> ", "
        <> jsonb retention.returnEvent
        <> ", "
        <> quoteLiteral (periodName retention.period)
        <> ", now() - "
        <> days retention.lookbackDays
        <> ", now(), "
        <> T.pack (show retention.periods)
        <> ")"
    ]

metricView :: Project -> Metric -> T.Text
metricView project metric =
  T.unlines
    ( [ "CREATE OR REPLACE VIEW reporting." <> prefix project "metric" metric.name <> " AS"
      , "SELECT date_trunc('day', event.time) AS day, count(*) AS events, count(DISTINCT COALESCE(event.person_id::text, 'd:' || event.device_id)) AS people, "
          <> maybe "NULL::double precision" (measured "event.properties") metric.measure
          <> " AS value"
      , "FROM event"
      , "JOIN project ON project.id = event.project_id"
      , "WHERE project.slug = " <> quoteLiteral project.slug
      , "  AND project.environment = " <> quoteLiteral project.environment
      , "  AND event.name = " <> quoteLiteral metric.event
      ]
        <> ["  AND event.properties @> " <> jsonb metric.filters | not (null metric.filters)]
        <> ["GROUP BY 1"]
    )

measured :: T.Text -> Measure -> T.Text
measured properties measure = case measure.aggregate of
  Sum -> "sum(" <> number <> ")"
  Average -> "avg(" <> number <> ")"
  Minimum -> "min(" <> number <> ")"
  Maximum -> "max(" <> number <> ")"
  Median -> percentile "0.5"
  P95 -> percentile "0.95"
  P99 -> percentile "0.99"
 where
  key = quoteLiteral measure.property
  number = "CASE WHEN jsonb_typeof(" <> properties <> " -> " <> key <> ") = 'number' THEN (" <> properties <> " ->> " <> key <> ")::double precision END"
  percentile fraction = "percentile_cont(" <> fraction <> ") WITHIN GROUP (ORDER BY " <> number <> ")"

analyticsSql :: Project -> Analytics -> [T.Text]
analyticsSql project analytics =
  fmap (funnelView project) analytics.funnels
    <> fmap (retentionView project) analytics.retention
    <> fmap (metricView project) analytics.metrics

declaredViews :: Project -> [T.Text]
declaredViews project =
  fmap (viewName project) project.cohorts
    <> fmap (prefix project "funnel" . (.name)) analytics.funnels
    <> fmap (prefix project "retention" . (.name)) analytics.retention
    <> fmap (prefix project "metric" . (.name)) analytics.metrics
 where
  analytics = fromMaybe emptyAnalytics project.analytics

staleViews :: [Project] -> T.Text
staleViews projects =
  T.unlines
    [ "DO $$"
    , "DECLARE"
    , "  stale text;"
    , "BEGIN"
    , "  FOR stale IN"
    , "    SELECT viewname FROM pg_views"
    , "    WHERE schemaname = 'reporting'"
    , "      AND viewname ~ '^(cohort|funnel|retention|metric)_'"
    , "      AND NOT (viewname = ANY (ARRAY[" <> T.intercalate ", " (fmap quoteLiteral (concatMap declaredViews projects)) <> "]::text[]))"
    , "  LOOP"
    , "    EXECUTE format('DROP VIEW reporting.%I', stale);"
    , "  END LOOP;"
    , "END"
    , "$$"
    ]

jsonb :: (ToJSON a) => a -> T.Text
jsonb value = quoteLiteral (TL.toStrict (AesonText.encodeToLazyText (Aeson.toJSON value))) <> "::jsonb"
