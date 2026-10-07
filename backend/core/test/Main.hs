module Main (main) where

import Control.Monad (unless)
import Hedgehog (checkParallel)
import System.Exit (exitFailure)
import Test.Peculiar.Insights.Core.Analytics qualified as Analytics
import Test.Peculiar.Insights.Core.Cohort qualified as Cohort
import Test.Peculiar.Insights.Core.Fingerprint qualified as Fingerprint
import Test.Peculiar.Insights.Core.Ingest qualified as Ingest
import Test.Peculiar.Insights.Core.Issue qualified as Issue
import Test.Peculiar.Insights.Core.Metrics qualified as Metrics
import Test.Peculiar.Insights.Core.Profile qualified as Profile
import Test.Peculiar.Insights.Core.RateLimit qualified as RateLimit
import Test.Peculiar.Insights.Core.Symbols qualified as Symbols
import Test.Peculiar.Insights.Core.Time qualified as Time
import Test.Peculiar.Insights.Core.Validate qualified as Validate
import Test.Peculiar.Insights.Core.Value qualified as Value

main :: IO ()
main = do
  results <-
    traverse
      checkParallel
      [ Value.tests
      , Time.tests
      , Validate.tests
      , Fingerprint.tests
      , Ingest.tests
      , Cohort.tests
      , Analytics.tests
      , Profile.tests
      , Issue.tests
      , RateLimit.tests
      , Metrics.tests
      , Symbols.tests
      ]
  unless (and results) exitFailure
