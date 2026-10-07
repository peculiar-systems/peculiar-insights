module Peculiar.Insights.Core.Metrics
  ( Kind (..)
  , Descriptor (..)
  , Series (..)
  , Registry
  , emptyRegistry
  , add
  , put
  , descriptors
  , render
  ) where

import Data.List (sortOn)
import Data.Map.Strict qualified as Map
import Data.Text qualified as T

data Kind = Counter | Gauge
  deriving stock (Eq, Show, Enum, Bounded)

data Descriptor = Descriptor
  { name :: T.Text
  , kind :: Kind
  , help :: T.Text
  }
  deriving stock (Eq, Show)

data Series = Series
  { name :: T.Text
  , labels :: [(T.Text, T.Text)]
  }
  deriving stock (Eq, Ord, Show)

type Registry = Map.Map Series Double

emptyRegistry :: Registry
emptyRegistry = Map.empty

add :: Series -> Double -> Registry -> Registry
add series = Map.insertWith (+) (ordered series)

put :: Series -> Double -> Registry -> Registry
put series = Map.insert (ordered series)

ordered :: Series -> Series
ordered series = Series{name = series.name, labels = sortOn fst series.labels}

descriptors :: [Descriptor]
descriptors =
  [ Descriptor "insights_requests_total" Counter "Calls answered, by method and gRPC status code."
  , Descriptor "insights_request_seconds_total" Counter "Seconds spent answering calls, by method."
  , Descriptor "insights_items_total" Counter "Items received in batches, by project, environment and outcome."
  , Descriptor "insights_rate_limited_total" Counter "Calls refused for exceeding a rate limit, by scope, project and environment."
  , Descriptor "insights_storage_failures_total" Counter "Storage operations that failed, by operation."
  , Descriptor "insights_maintenance_runs_total" Counter "Maintenance passes, by result."
  , Descriptor "insights_maintenance_last_success_timestamp_seconds" Gauge "Unix time of the last maintenance pass that succeeded."
  , Descriptor "insights_projects" Gauge "Environments the server accepts data for."
  , Descriptor "insights_start_timestamp_seconds" Gauge "Unix time the server started."
  ]

render :: [Descriptor] -> Registry -> T.Text
render known registry = T.concat (concatMap family known)
 where
  family descriptor =
    case [(series, value) | (series, value) <- Map.toList registry, series.name == descriptor.name] of
      [] -> []
      samples ->
        [ "# HELP " <> descriptor.name <> " " <> escapeHelp descriptor.help <> "\n"
        , "# TYPE " <> descriptor.name <> " " <> kindName descriptor.kind <> "\n"
        ]
          <> fmap sample samples
  sample (series, value) = series.name <> labelled series.labels <> " " <> number value <> "\n"

kindName :: Kind -> T.Text
kindName = \case
  Counter -> "counter"
  Gauge -> "gauge"

labelled :: [(T.Text, T.Text)] -> T.Text
labelled = \case
  [] -> ""
  labels -> "{" <> T.intercalate "," [key <> "=\"" <> escapeLabel value <> "\"" | (key, value) <- labels] <> "}"

escapeLabel :: T.Text -> T.Text
escapeLabel = T.replace "\n" "\\n" . T.replace "\"" "\\\"" . T.replace "\\" "\\\\"

escapeHelp :: T.Text -> T.Text
escapeHelp = T.replace "\n" "\\n" . T.replace "\\" "\\\\"

number :: Double -> T.Text
number value
  | value == fromIntegral whole = T.pack (show whole)
  | otherwise = T.pack (show value)
 where
  whole = round value :: Integer
