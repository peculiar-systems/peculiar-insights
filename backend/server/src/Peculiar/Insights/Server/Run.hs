module Peculiar.Insights.Server.Run
  ( run
  , check
  , Startup (..)
  , Wiring (..)
  , start
  , maintainOnce
  ) where

import Control.Concurrent.Async (concurrently_, withAsync)
import Data.Aeson (object, toJSON, (.=))
import Data.Text qualified as T
import Data.Text.Encoding qualified as TE
import Data.Time.Clock.POSIX (utcTimeToPOSIXSeconds)
import Peculiar.Insights.Core.Config (Config (..), Listen (..), Symbols (..), TlsFiles (..))
import Peculiar.Insights.Core.Metrics (Series (..))
import Peculiar.Insights.Core.Time (defaultWindow)
import Peculiar.Insights.Core.Validate (defaultLimits)
import Peculiar.Insights.Server.Api (ingest)
import Peculiar.Insights.Server.Clock (Clock (..), systemClock)
import Peculiar.Insights.Server.Config (Loaded (..), describeLoadError, inspect, load)
import Peculiar.Insights.Server.Db (Db (..), describeDbError, withDb)
import Peculiar.Insights.Server.Env
import Peculiar.Insights.Server.Grafana (grafanaOf)
import Peculiar.Insights.Server.Housekeeping (Startup (..), maintainOnce, maintenance)
import Peculiar.Insights.Server.Journal (Journal (..), stdoutJournal)
import Peculiar.Insights.Server.Limiter (newLimiter)
import Peculiar.Insights.Server.Maintain (analyticsStatements, cohortStatements, grantStatements, staleStatements)
import Peculiar.Insights.Server.Manage (jsonOnlyForManage, manage)
import Peculiar.Insights.Server.Metrics (Metrics (..), newMetrics, observing, serveMetrics)
import Peculiar.Insights.Server.Projects (Registered (..), mkProjects)
import Peculiar.Insights.Server.Symbolicator (Symbolicator, withInstalledSymbolicator)
import Peculiar.Insights.Server.Symbols (symbols)
import Peculiar.Insights.Server.Uploads (mkUploads)
import Peculiar.Rpc qualified as Rpc
import System.Exit (exitFailure)

data Wiring = Wiring
  { journal :: Journal
  , clock :: Clock
  , metrics :: Metrics
  , db :: Db
  , symbolicator :: Symbolicator
  }

run :: FilePath -> IO ()
run path = do
  journal <- stdoutJournal
  loaded <- load path >>= either (halt journal "config" . describeLoadError) pure
  withDb loaded.config.database \db -> withInstalledSymbolicator journal \symbolicator -> do
    metrics <- newMetrics
    startup <- start Wiring{journal, clock = systemClock, metrics, db, symbolicator} loaded >>= either (halt journal "startup") pure
    tls <- case loaded.config.listen.tls of
      Nothing -> pure Nothing
      Just files -> Rpc.tlsFromFiles files.certificate files.key >>= either (halt journal "tls") (pure . Just)
    statuses <- Rpc.newStatuses
    let settings =
          Rpc.defaultSettings
            { Rpc.host = loaded.config.listen.host
            , Rpc.port = loaded.config.listen.port
            , Rpc.web = Rpc.defaultWeb{Rpc.cors = Just (corsOf loaded.config.listen.corsOrigins), Rpc.receiveLimit = Just (4 * 1024 * 1024)}
            , Rpc.onListening = journal.write "listening" . toJSON
            , Rpc.report = journal.write "request-failed" . toJSON . show
            , Rpc.tls = tls
            , Rpc.interceptor = jsonOnlyForManage <> observing "peculiar.insights.v1.Ingest" metrics
            }
        serving = Rpc.serveEndpoints settings [Rpc.endpoint (ingest startup.env), Rpc.endpoint (manage startup.env), Rpc.endpoint (symbols startup.env), Rpc.health statuses]
    withAsync (maintenance startup) \_ -> case loaded.config.monitoring of
      Nothing -> serving
      Just monitoring -> do
        journal.write "monitoring" (toJSON monitoring)
        concurrently_ serving (serveMetrics monitoring metrics)

check :: FilePath -> IO ()
check path = do
  journal <- stdoutJournal
  inspect path >>= \case
    Left failure -> halt journal "config" (describeLoadError failure)
    Right config -> journal.write "config-valid" (object ["projects" .= length config.projects])

halt :: Journal -> T.Text -> T.Text -> IO a
halt journal kind reason = journal.write kind (toJSON reason) *> exitFailure

corsOf :: [T.Text] -> Rpc.Cors
corsOf = \case
  [] -> readable
  origins -> readable{Rpc.origins = Rpc.OnlyOrigins (fmap TE.encodeUtf8 origins)}
 where
  readable = Rpc.permissive{Rpc.expose = ["x-peculiar-retry-after-ms"]}

start :: Wiring -> Loaded -> IO (Either T.Text Startup)
start Wiring{journal, clock, metrics, db, symbolicator} loaded = do
  outcome <-
    sequenceSteps
      [ ("migrate", db.migrateSchema)
      , ("verify", db.verify)
      ]
  linked <- grafanaOf loaded.config.grafana
  case (outcome, linked) of
    (Left failure, _) -> pure (Left failure)
    (_, Left failure) -> pure (Left ("grafana: " <> failure))
    (Right (), Right grafana) ->
      db.registerProjects loaded.config.projects >>= \case
        Left failure -> pure (Left (describeDbError failure))
        Right registered -> do
          let statements = staleStatements registered <> cohortStatements registered <> analyticsStatements registered <> foldMap grantStatements loaded.config.reportingRole
          db.execute statements >>= \case
            Left failure -> pure (Left (describeDbError failure))
            Right () -> do
              limiter <- newLimiter
              now <- clock.now
              let projects = mkProjects [(key, entry) | (key, project) <- loaded.keys, entry <- registered, entry.project == project]
                  uploads = mkUploads loaded.config.symbols.directory loaded.config.symbols.maxUploadBytes loaded.uploadKeys
                  env = Env{db, clock, journal, projects, limits = defaultLimits, window = defaultWindow, limiter, peerLimit = loaded.config.peerLimit, metrics, grafana, symbolicator, uploads}
              metrics.gauge Series{name = "insights_projects", labels = []} (fromIntegral (length registered))
              metrics.gauge Series{name = "insights_start_timestamp_seconds", labels = []} (realToFrac (utcTimeToPOSIXSeconds now))
              journal.write "started" (object ["projects" .= length registered])
              pure (Right Startup{env, registered})
 where
  sequenceSteps [] = pure (Right ())
  sequenceSteps ((name, step) : rest) =
    step >>= \case
      Left failure -> pure (Left (name <> ": " <> describeDbError failure))
      Right () -> sequenceSteps rest
