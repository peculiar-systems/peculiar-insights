{-# LANGUAGE TemplateHaskell #-}

module Peculiar.Insights.Sdk.Client
  ( IngestClient (..)
  , Endpoint (..)
  , withRemote
  ) where

import Data.ByteString qualified as BS
import Data.Text qualified as T
import Peculiar.Rpc qualified as Rpc
import Proto.Peculiar.Insights.V1.Ingest

Rpc.deriveClient ''Ingest

data Endpoint = Endpoint
  { host :: T.Text
  , port :: Int
  , tls :: Bool
  }
  deriving stock (Eq, Show)

withRemote :: Endpoint -> BS.ByteString -> Integer -> (IngestClient -> IO a) -> IO a
withRemote endpoint key callTimeoutSeconds use = Rpc.withNativeClient security endpoint.host endpoint.port (use . Rpc.client options)
 where
  security = if endpoint.tls then Rpc.Secure Rpc.systemTls else Rpc.Plaintext
  options =
    Rpc.defaultOptions
      { Rpc.deadline = Just (Rpc.seconds callTimeoutSeconds)
      , Rpc.requestMetadata = Rpc.header "authorization" ("Bearer " <> key) <> Rpc.header "x-peculiar-protocol" "1"
      }
