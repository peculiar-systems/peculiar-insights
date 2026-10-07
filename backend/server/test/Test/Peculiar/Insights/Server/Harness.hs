module Test.Peculiar.Insights.Server.Harness
  ( withServer
  , withLimited
  , withManaged
  , withSymbols
  , remote
  , remoteJson
  , managing
  , natively
  , granted
  , sampleEvent
  , request
  ) where

import Control.Concurrent.Async (withAsync)
import Control.Concurrent.MVar (newEmptyMVar, putMVar, takeMVar)
import Data.ByteString qualified as BS
import Data.Text qualified as T
import Data.Text.Encoding qualified as TE
import Network.HTTP.Client qualified as Http
import Peculiar.Insights.Core.Config (PeerLimit, Project (..), Rate)
import Peculiar.Insights.Core.Time (defaultWindow)
import Peculiar.Insights.Core.Validate (defaultLimits)
import Peculiar.Insights.Server.Api (IngestClient, ingest)
import Peculiar.Insights.Server.Clock (systemClock)
import Peculiar.Insights.Server.Db (Db)
import Peculiar.Insights.Server.Env (Env (..))
import Peculiar.Insights.Server.Grafana (Grafana, absentGrafana, identityHeader)
import Peculiar.Insights.Server.Journal (silentJournal)
import Peculiar.Insights.Server.Limiter (newLimiter)
import Peculiar.Insights.Server.Manage (ManageClient, jsonOnlyForManage, manage)
import Peculiar.Insights.Server.Metrics (Metrics (..), newMetrics, observing)
import Peculiar.Insights.Server.Projects (Registered (..), mkProjects)
import Peculiar.Insights.Server.Symbolicator (Symbolicator, absentSymbolicator)
import Peculiar.Insights.Server.Symbols (symbols)
import Peculiar.Insights.Server.Uploads (Uploads, mkUploads)
import Peculiar.Rpc qualified as Rpc
import Test.Peculiar.Insights.Server.Db (register)
import Test.Peculiar.Insights.Server.Requests (granted, request, sampleEvent)

withServer :: Db -> (Int -> IO a) -> IO a
withServer db use = withLimited db Nothing Nothing \port _ -> use port

withLimited :: Db -> Maybe Rate -> Maybe PeerLimit -> (Int -> IO T.Text -> IO a) -> IO a
withLimited db keyRate peerLimit = withServing db Serving{grafana = absentGrafana, symbolicator = absentSymbolicator, uploads = unused, keyRate, peerLimit}

withManaged :: Db -> Grafana -> (Int -> IO a) -> IO a
withManaged db grafana use = withServing db Serving{grafana, symbolicator = absentSymbolicator, uploads = unused, keyRate = Nothing, peerLimit = Nothing} \port _ -> use port

withSymbols :: Db -> Symbolicator -> Uploads -> (Int -> IO a) -> IO a
withSymbols db symbolicator uploads use = withServing db Serving{grafana = absentGrafana, symbolicator, uploads, keyRate = Nothing, peerLimit = Nothing} \port _ -> use port

data Serving = Serving
  { grafana :: Grafana
  , symbolicator :: Symbolicator
  , uploads :: Uploads
  , keyRate :: Maybe Rate
  , peerLimit :: Maybe PeerLimit
  }

unused :: Uploads
unused = mkUploads "/nonexistent" 1 []

withServing :: Db -> Serving -> (Int -> IO T.Text -> IO a) -> IO a
withServing db Serving{grafana, symbolicator, uploads, keyRate, peerLimit} use = do
  registered <- register db
  bound <- newEmptyMVar
  limiter <- newLimiter
  statuses <- Rpc.newStatuses
  metrics <- newMetrics
  let limited = registered{project = registered.project{rateLimit = keyRate}}
      env =
        Env
          { db
          , clock = systemClock
          , journal = silentJournal
          , projects = mkProjects [("test-key", limited)]
          , limits = defaultLimits
          , window = defaultWindow
          , limiter
          , peerLimit
          , metrics
          , grafana
          , symbolicator
          , uploads
          }
      settings =
        Rpc.defaultSettings
          { Rpc.port = 0
          , Rpc.onListening = putMVar bound
          , Rpc.calls =
              Rpc.defaultCalls
                { Rpc.report = const (pure ())
                , Rpc.interceptor = jsonOnlyForManage <> observing "peculiar.insights.v1.Ingest" metrics
                }
          }
  withAsync (Rpc.serveEndpoints settings [Rpc.endpoint (ingest env), Rpc.endpoint (manage env), Rpc.endpoint (symbols env), Rpc.health statuses]) \_ -> takeMVar bound >>= (`use` metrics.exposition)

natively :: Int -> T.Text -> (IngestClient -> IO a) -> IO a
natively port key use = Rpc.withNativeClient Rpc.Plaintext "127.0.0.1" port (use . Rpc.client options)
 where
  options = Rpc.defaultOptions{Rpc.requestMetadata = Rpc.header "authorization" ("Bearer " <> TE.encodeUtf8 key)}

remoteJson :: Int -> T.Text -> IO IngestClient
remoteJson port key = do
  target <- connectTarget port
  pure (Rpc.client Rpc.defaultOptions{Rpc.codec = Rpc.Json, Rpc.requestMetadata = Rpc.header "authorization" ("Bearer " <> TE.encodeUtf8 key)} (Rpc.Http1 target))

managing :: Int -> Maybe BS.ByteString -> IO ManageClient
managing port identity = do
  target <- connectTarget port
  pure (Rpc.client Rpc.defaultOptions{Rpc.codec = Rpc.Json, Rpc.requestMetadata = foldMap (Rpc.header identityHeader) identity} (Rpc.Http1 target))

connectTarget :: Int -> IO Rpc.Target
connectTarget port = do
  manager <- Http.newManager Http.defaultManagerSettings
  either (ioError . userError . T.unpack) pure (Rpc.web manager Rpc.Connect (T.pack ("http://127.0.0.1:" <> show port)))

remote :: Int -> Maybe T.Text -> IO IngestClient
remote port key = do
  manager <- Http.newManager Http.defaultManagerSettings
  target <- either (ioError . userError . T.unpack) pure (Rpc.web manager Rpc.GrpcWeb (T.pack ("http://127.0.0.1:" <> show port)))
  let requestMetadata = foldMap (\k -> Rpc.header "authorization" ("Bearer " <> textBytes k)) key
  pure (Rpc.client Rpc.defaultOptions{Rpc.requestMetadata} (Rpc.Http1 target))
 where
  textBytes = TE.encodeUtf8
