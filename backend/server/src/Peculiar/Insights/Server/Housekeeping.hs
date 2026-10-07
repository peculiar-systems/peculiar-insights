module Peculiar.Insights.Server.Housekeeping
  ( Startup (..)
  , maintainOnce
  , maintenance
  ) where

import Control.Concurrent (threadDelay)
import Control.Exception (SomeException, try)
import Control.Monad (forever)
import Data.Aeson (object, toJSON)
import Data.Bifunctor (first)
import Data.Text qualified as T
import Data.Time (utctDay)
import Data.Time.Clock.POSIX (utcTimeToPOSIXSeconds)
import Peculiar.Insights.Core.Config (Project (..))
import Peculiar.Insights.Core.Metrics (Series (..))
import Peculiar.Insights.Server.Clock (Clock (..))
import Peculiar.Insights.Server.Db (Db (..), describeDbError)
import Peculiar.Insights.Server.Env (Env (..))
import Peculiar.Insights.Server.Journal (Journal (..))
import Peculiar.Insights.Server.Maintain (dropStatements, partitionStatements, retentions)
import Peculiar.Insights.Server.Metrics (Metrics (..))
import Peculiar.Insights.Server.Projects (Registered (..))
import Peculiar.Insights.Server.SymbolStore (pruneSymbols)

data Startup = Startup
  { env :: Env
  , registered :: [Registered]
  }

maintainOnce :: Startup -> IO (Either T.Text ())
maintainOnce startup = do
  now <- startup.env.clock.now
  let days = [d | Registered{project} <- startup.registered, Just d <- [project.retentionDays]]
      everyProjectRetains = length days == length startup.registered && not (null days)
      drops = if everyProjectRetains then dropStatements (utctDay now) (maximum' days) else []
  startup.env.db.execute (partitionStatements (utctDay now) <> drops) >>= \case
    Left failure -> pure (Left (describeDbError failure))
    Right () ->
      startup.env.db.retain now (retentions now startup.registered) >>= \case
        Left failure -> pure (Left (describeDbError failure))
        Right () -> first describeDbError <$> pruneSymbols startup.env now startup.registered
 where
  maximum' = foldr max 0

maintenance :: Startup -> IO ()
maintenance startup = forever do
  outcome <- try @SomeException (maintainOnce startup)
  now <- startup.env.clock.now
  let ran result = startup.env.metrics.count Series{name = "insights_maintenance_runs_total", labels = [("result", result)]} 1
  case outcome of
    Left failure -> startup.env.journal.write "maintenance-crashed" (toJSON (show failure)) *> ran "crashed"
    Right (Left failure) -> startup.env.journal.write "maintenance-failed" (toJSON failure) *> ran "failed"
    Right (Right ()) -> do
      startup.env.journal.write "maintained" (object [])
      startup.env.metrics.gauge Series{name = "insights_maintenance_last_success_timestamp_seconds", labels = []} (realToFrac (utcTimeToPOSIXSeconds now))
      ran "succeeded"
  threadDelay (3600 * 1_000_000)
