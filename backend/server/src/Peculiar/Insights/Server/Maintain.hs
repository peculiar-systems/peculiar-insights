module Peculiar.Insights.Server.Maintain
  ( partitionStatements
  , dropStatements
  , grantStatements
  , cohortStatements
  , analyticsStatements
  , staleStatements
  , retentions
  , quoteIdentifier
  ) where

import Data.Maybe (fromMaybe)
import Data.Text qualified as T
import Data.Time (Day, UTCTime (..), addUTCTime, toGregorian)
import Data.Time.Calendar (addGregorianMonthsClip, fromGregorian)
import Peculiar.Insights.Core.Analytics (analyticsSql, staleViews)
import Peculiar.Insights.Core.Cohort (viewSql)
import Peculiar.Insights.Core.Config (Project (..), emptyAnalytics)
import Peculiar.Insights.Server.Db (Retention (..))
import Peculiar.Insights.Server.Projects (Registered (..))

partitioned :: [T.Text]
partitioned = ["event", "crash"]

monthStart :: Day -> Day
monthStart day = let (year, month, _) = toGregorian day in fromGregorian year month 1

partitionName :: T.Text -> Day -> T.Text
partitionName table day =
  let (year, month, _) = toGregorian day
   in table <> "_y" <> T.pack (show year) <> "m" <> T.justifyRight 2 '0' (T.pack (show month))

isoDay :: Day -> T.Text
isoDay = T.pack . show

partitionStatements :: Day -> [T.Text]
partitionStatements today =
  [ "CREATE TABLE IF NOT EXISTS "
      <> partitionName table start
      <> " PARTITION OF "
      <> table
      <> " FOR VALUES FROM ('"
      <> isoDay start
      <> "') TO ('"
      <> isoDay (addGregorianMonthsClip 1 start)
      <> "')"
  | table <- partitioned
  , offset <- [-4 .. 1]
  , let start = addGregorianMonthsClip offset (monthStart today)
  ]

dropStatements :: Day -> Int -> [T.Text]
dropStatements today retentionDays =
  [ "DROP TABLE IF EXISTS " <> partitionName table start
  | table <- partitioned
  , offset <- [-36 .. -1]
  , let start = addGregorianMonthsClip offset (monthStart today)
  , addGregorianMonthsClip 1 start < cutoff
  ]
 where
  cutoff = utctDay (addUTCTime (negate (fromIntegral retentionDays) * 86400) (UTCTime today 0))

grantStatements :: T.Text -> [T.Text]
grantStatements role =
  [ "GRANT USAGE ON SCHEMA reporting TO " <> quoted
  , "GRANT SELECT ON ALL TABLES IN SCHEMA reporting TO " <> quoted
  , "GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA reporting TO " <> quoted
  , "ALTER DEFAULT PRIVILEGES IN SCHEMA reporting GRANT SELECT ON TABLES TO " <> quoted
  ]
 where
  quoted = quoteIdentifier role

cohortStatements :: [Registered] -> [T.Text]
cohortStatements registered =
  [viewSql project cohort | Registered{project} <- registered, cohort <- project.cohorts]

analyticsStatements :: [Registered] -> [T.Text]
analyticsStatements registered =
  concat [analyticsSql project (fromMaybe emptyAnalytics project.analytics) | Registered{project} <- registered]

staleStatements :: [Registered] -> [T.Text]
staleStatements registered = [staleViews [project | Registered{project} <- registered]]

retentions :: UTCTime -> [Registered] -> [Retention]
retentions now registered =
  [ Retention{registered = entry, cutoff = addUTCTime (negate (fromIntegral days) * 86400) now}
  | entry@Registered{project} <- registered
  , Just days <- [project.retentionDays]
  ]

quoteIdentifier :: T.Text -> T.Text
quoteIdentifier name = "\"" <> T.replace "\"" "\"\"" name <> "\""
