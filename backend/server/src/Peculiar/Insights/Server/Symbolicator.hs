{-# LANGUAGE TemplateHaskell #-}

module Peculiar.Insights.Server.Symbolicator
  ( Symbolicator (..)
  , SymbolicatorError (..)
  , Indexed (..)
  , describeSymbolicatorError
  , withSymbolicator
  , withInstalledSymbolicator
  , absentSymbolicator
  ) where

import Control.Concurrent (threadDelay)
import Control.Exception (IOException, try)
import Data.Aeson (toJSON)
import Data.ProtoLens (defMessage)
import Data.ProtoLens.Field (HasField)
import Data.ProtoLens.Labels ()
import Data.Text qualified as T
import Data.Word (Word32, Word64)
import Lens.Family2 ((&), (.~), (^.))
import Peculiar.Insights.Core.Symbols (Format (..), JvmFrame (..), Located (..))
import Peculiar.Insights.Server.Journal (Journal (..))
import Peculiar.Rpc qualified as Rpc
import Proto.Peculiar.Insights.V1.Symbolicator qualified as Wire
import System.Directory (doesPathExist)
import System.Environment (lookupEnv)
import System.FilePath ((</>))
import System.IO.Temp (withSystemTempDirectory)
import System.Process (proc, withCreateProcess)

Rpc.deriveClient ''Wire.Symbolicator

data SymbolicatorError
  = Unreachable T.Text
  | Rejected T.Text
  deriving stock (Eq, Show)

describeSymbolicatorError :: SymbolicatorError -> T.Text
describeSymbolicatorError = \case
  Unreachable reason -> "the symbolicator is unreachable: " <> reason
  Rejected reason -> reason

data Indexed = Indexed
  { identifier :: T.Text
  , path :: FilePath
  }
  deriving stock (Eq, Show)

data Symbolicator = Symbolicator
  { inspect :: Format -> FilePath -> FilePath -> IO (Either SymbolicatorError [Indexed])
  , lookupNative :: FilePath -> [Word64] -> IO (Either SymbolicatorError [[Located]])
  , retrace :: FilePath -> [JvmFrame] -> IO (Either SymbolicatorError [[Located]])
  , mapSource :: FilePath -> [(Word32, Word32)] -> IO (Either SymbolicatorError [[Located]])
  }

absentSymbolicator :: Symbolicator
absentSymbolicator =
  Symbolicator
    { inspect = \_ _ _ -> absent
    , lookupNative = \_ _ -> absent
    , retrace = \_ _ -> absent
    , mapSource = \_ _ -> absent
    }
 where
  absent = pure (Left (Unreachable "no symbolicator is running"))

withInstalledSymbolicator :: Journal -> (Symbolicator -> IO a) -> IO a
withInstalledSymbolicator journal use =
  lookupEnv "PECULIAR_INSIGHTS_SYMBOLICATOR" >>= \case
    Just executable -> withSymbolicator executable use
    Nothing -> do
      journal.write "symbolicator-absent" (toJSON ("PECULIAR_INSIGHTS_SYMBOLICATOR is not set; symbols are stored but not read" :: T.Text))
      use absentSymbolicator

withSymbolicator :: FilePath -> (Symbolicator -> IO a) -> IO a
withSymbolicator executable use =
  withSystemTempDirectory "symbolicator" \directory -> do
    let socket = directory </> "socket"
    withCreateProcess (proc executable ["--socket", socket]) \_ _ _ _ -> do
      awaitSocket socket (200 :: Int)
      Rpc.connect Rpc.defaultDialing (Rpc.Unix socket) \connection -> do
        let transport = Rpc.Http2 connection Rpc.Grpc
            indexing = Rpc.client Rpc.defaultOptions{Rpc.deadline = Just (Rpc.seconds 1800)} transport :: SymbolicatorClient
            looking = Rpc.client Rpc.defaultOptions{Rpc.deadline = Just (Rpc.seconds 60)} transport :: SymbolicatorClient
        use (symbolicatorOf indexing looking)
 where
  awaitSocket socket remaining = do
    present <- doesPathExist socket
    if present || remaining <= 0 then pure () else threadDelay 50_000 *> awaitSocket socket (remaining - 1)

symbolicatorOf :: SymbolicatorClient -> SymbolicatorClient -> Symbolicator
symbolicatorOf indexing looking =
  Symbolicator
    { inspect = \format path cache ->
        calling (fmap indexedOf . (^. #entries)) do
          indexing.inspect (defMessage & #path .~ T.pack path & #format .~ wireFormat format & #cacheDirectory .~ T.pack cache)
    , lookupNative = \path addresses ->
        calling resolvedOf do
          looking.lookupNative (defMessage & #path .~ T.pack path & #addresses .~ addresses)
    , retrace = \path frames ->
        calling resolvedOf do
          looking.retrace (defMessage & #path .~ T.pack path & #frames .~ fmap jvmFrame frames)
    , mapSource = \path positions ->
        calling resolvedOf do
          looking.mapSource (defMessage & #path .~ T.pack path & #positions .~ fmap position positions)
    }
 where
  indexedOf entry = Indexed{identifier = entry ^. #identifier, path = T.unpack (entry ^. #path)}
  jvmFrame frame = defMessage & #className .~ frame.className & #method .~ frame.method & #file .~ frame.file & #line .~ frame.line
  position (line, column) = defMessage & #line .~ line & #column .~ column

resolvedOf :: (HasField response "resolved" [Wire.Resolved]) => response -> [[Located]]
resolvedOf response = fmap (fmap locatedOf . (^. #frames)) (response ^. #resolved)

locatedOf :: Wire.SourceFrame -> Located
locatedOf frame =
  Located
    { moduleName = frame ^. #module'
    , function = frame ^. #function
    , file = frame ^. #file
    , line = frame ^. #line
    , column = frame ^. #column
    }

wireFormat :: Format -> Wire.SymbolFormat
wireFormat = \case
  NativeObjects -> Wire.SYMBOL_FORMAT_NATIVE
  Mapping -> Wire.SYMBOL_FORMAT_R8_MAPPING
  SourceMap -> Wire.SYMBOL_FORMAT_SOURCE_MAP

calling :: (response -> a) -> IO response -> IO (Either SymbolicatorError a)
calling answer call =
  try @IOException (try @Rpc.RpcError call) >>= \case
    Left failure -> pure (Left (Unreachable (T.pack (show failure))))
    Right (Left failure)
      | failure.status.code == Rpc.InvalidArgument -> pure (Left (Rejected failure.status.message))
      | otherwise -> pure (Left (Unreachable failure.status.message))
    Right (Right response) -> pure (Right (answer response))
