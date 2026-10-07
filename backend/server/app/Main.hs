module Main (main) where

import Peculiar.Insights.Server.Run (check, run)
import System.Environment (getArgs)
import System.Exit (exitFailure)
import System.IO (hPutStrLn, stderr)

main :: IO ()
main =
  getArgs >>= \case
    ["--check", path] -> check path
    [path] -> run path
    _ -> hPutStrLn stderr "usage: peculiar-insights-server [--check] <config.json>" *> exitFailure
