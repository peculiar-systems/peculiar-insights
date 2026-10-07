module Test.Peculiar.Insights.Server.Postgres
  ( withPostgres
  ) where

import Control.Exception (bracket_)
import Data.Text qualified as T
import System.FilePath ((</>))
import System.IO.Temp (withSystemTempDirectory)
import System.Process (callProcess)

withPostgres :: (T.Text -> IO a) -> IO a
withPostgres use = withSystemTempDirectory "pg" \dir -> do
  let dataDir = dir </> "data"
      port = "54329"
  callProcess "initdb" ["-D", dataDir, "--no-locale", "-E", "UTF8", "-U", "tester", "--auth=trust", "--no-sync"]
  bracket_
    (callProcess "pg_ctl" ["-D", dataDir, "-o", "-k " <> dir <> " -h '' -p " <> port <> " -F", "-w", "-l", dir </> "log", "start"])
    (callProcess "pg_ctl" ["-D", dataDir, "-m", "immediate", "stop"])
    (use (T.pack ("host=" <> dir <> " port=" <> port <> " user=tester dbname=postgres")))
