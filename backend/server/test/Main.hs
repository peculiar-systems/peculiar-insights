module Main (main) where

import Control.Monad (unless)
import Hedgehog (checkSequential)
import Peculiar.Insights.Server.Db (withDb)
import Peculiar.Insights.Server.Symbolicator (withSymbolicator)
import System.Environment (getEnv)
import System.Exit (exitFailure)
import System.IO.Temp (withSystemTempDirectory)
import Test.Peculiar.Insights.Server.Analysis qualified as Analysis
import Test.Peculiar.Insights.Server.Api qualified as Api
import Test.Peculiar.Insights.Server.Dashboards qualified as Dashboards
import Test.Peculiar.Insights.Server.Db qualified as Db
import Test.Peculiar.Insights.Server.Frames qualified as Frames
import Test.Peculiar.Insights.Server.Manage qualified as Manage
import Test.Peculiar.Insights.Server.Postgres (withPostgres)
import Test.Peculiar.Insights.Server.Regrouping qualified as Regrouping
import Test.Peculiar.Insights.Server.SymbolFixtures (suiteOf)
import Test.Peculiar.Insights.Server.Symbols qualified as Symbols

main :: IO ()
main = withPostgres \conninfo -> withDb conninfo \db -> do
  adapter <- getEnv "PECULIAR_INSIGHTS_SYMBOLICATOR"
  withSymbolicator adapter \symbolicator -> withSystemTempDirectory "symbols" \scratch -> do
    dashboards <- Dashboards.tests conninfo
    managing <- Manage.tests conninfo db
    suite <- suiteOf conninfo db symbolicator scratch
    results <- traverse checkSequential [Db.tests conninfo db, Analysis.tests conninfo db, Api.tests db, managing, Frames.tests conninfo db, dashboards, Symbols.tests suite, Regrouping.tests suite]
    unless (and results) exitFailure
