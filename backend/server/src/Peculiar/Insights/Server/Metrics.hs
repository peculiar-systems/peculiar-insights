module Peculiar.Insights.Server.Metrics
  ( Metrics (..)
  , HasMetrics (..)
  , newMetrics
  , silentMetrics
  , serveMetrics
  , exposing
  , observing
  , codeLabel
  ) where

import Control.Exception (SomeException, fromException, throwIO, try)
import Data.ByteString.Lazy qualified as LBS
import Data.Char (isUpper, toLower)
import Data.Functor (void)
import Data.IORef (newIORef, readIORef)
import Data.String (fromString)
import Data.Text qualified as T
import Data.Text.Encoding qualified as TE
import GHC.Clock (getMonotonicTime)
import GHC.IORef (atomicModifyIORef'_)
import Network.HTTP.Types (hContentType, methodGet, status200, status404)
import Network.Wai qualified as Wai
import Network.Wai.Handler.Warp qualified as Warp
import Peculiar.Insights.Core.Config (Monitoring (..))
import Peculiar.Insights.Core.Metrics (Series (..), add, descriptors, emptyRegistry, put, render)
import Peculiar.Rpc qualified as Rpc

data Metrics = Metrics
  { count :: Series -> Double -> IO ()
  , gauge :: Series -> Double -> IO ()
  , exposition :: IO T.Text
  }

class HasMetrics env where
  getMetrics :: env -> Metrics

silentMetrics :: Metrics
silentMetrics = Metrics{count = \_ _ -> pure (), gauge = \_ _ -> pure (), exposition = pure ""}

newMetrics :: IO Metrics
newMetrics = do
  registry <- newIORef emptyRegistry
  pure
    Metrics
      { count = \series amount -> void (atomicModifyIORef'_ registry (add series amount))
      , gauge = \series value -> void (atomicModifyIORef'_ registry (put series value))
      , exposition = render descriptors <$> readIORef registry
      }

serveMetrics :: Monitoring -> Metrics -> IO ()
serveMetrics monitoring metrics = Warp.runSettings settings (exposing metrics)
 where
  settings = Warp.setHost (fromString (T.unpack monitoring.host)) (Warp.setPort monitoring.port Warp.defaultSettings)

exposing :: Metrics -> Wai.Application
exposing metrics request respond
  | Wai.requestMethod request == methodGet && Wai.pathInfo request == ["metrics"] = do
      body <- metrics.exposition
      respond (Wai.responseLBS status200 [(hContentType, "text/plain; version=0.0.4; charset=utf-8")] (LBS.fromStrict (TE.encodeUtf8 body)))
  | otherwise = respond (Wai.responseLBS status404 [(hContentType, "text/plain; charset=utf-8")] "not found\n")

observing :: T.Text -> Metrics -> Rpc.Interceptor
observing service metrics = Rpc.Interceptor \route context continue ->
  if route.service /= service
    then continue context
    else do
      started <- getMonotonicTime
      outcome <- try @SomeException (continue context)
      finished <- getMonotonicTime
      let code = case outcome of
            Right _ -> "ok"
            Left failure -> maybe "internal" (\(rejected :: Rpc.RpcError) -> codeLabel rejected.status.code) (fromException failure)
      metrics.count Series{name = "insights_requests_total", labels = [("method", route.method), ("code", code)]} 1
      metrics.count Series{name = "insights_request_seconds_total", labels = [("method", route.method)]} (finished - started)
      either throwIO pure outcome

codeLabel :: Rpc.Code -> T.Text
codeLabel = T.pack . snake . show
 where
  snake = \case
    [] -> []
    first : rest -> toLower first : concatMap (\letter -> if isUpper letter then ['_', toLower letter] else [letter]) rest
