{-# LANGUAGE TemplateHaskell #-}

module Peculiar.Insights.Server.Symbols
  ( SymbolsServer (..)
  , SymbolsClient (..)
  , symbols
  ) where

import Control.Monad (unless, when)
import Data.Aeson (ToJSON, toJSON)
import Data.ByteString qualified as BS
import Data.Foldable (for_)
import Data.List.NonEmpty (NonEmpty (..))
import Data.List.NonEmpty qualified as NonEmpty
import Data.Map.Strict qualified as Map
import Data.ProtoLens (defMessage)
import Data.ProtoLens.Labels ()
import Data.Text qualified as T
import Data.Traversable (for)
import GHC.Generics (Generic, Generically (..))
import Lens.Family2 ((&), (.~), (^.))
import Peculiar.Insights.Core.Enum (enumerate)
import Peculiar.Insights.Core.Symbols (SymbolKind (..), kindName)
import Peculiar.Insights.Server.Api (storing)
import Peculiar.Insights.Server.Clock (Clock (..))
import Peculiar.Insights.Server.Env
import Peculiar.Insights.Server.Journal (Journal (..))
import Peculiar.Insights.Server.SymbolStore (Destination (..), Indexing (..), Received (..), Unindexed (..), indexing, keep, safeName)
import Peculiar.Insights.Server.Symbolicate (resymbolicate)
import Peculiar.Insights.Server.Symbolicator (SymbolicatorError (..), describeSymbolicatorError)
import Peculiar.Insights.Server.Uploads (Uploads (..), authorised)
import Peculiar.Rpc qualified as Rpc
import Proto.Peculiar.Insights.V1.Symbols (UploadRequest, UploadRequest'Part (..), UploadResponse)
import Proto.Peculiar.Insights.V1.Symbols qualified as Wire
import System.Directory (createDirectoryIfMissing, removePathForcibly)
import System.FilePath ((</>))
import System.IO.Temp (withTempDirectory)

Rpc.deriveService ''Wire.Symbols

type Uploading env = (HasDb env, HasClock env, HasJournal env, HasMetrics env, HasSymbolicator env, HasUploads env)

data Uploaded = Uploaded
  { project :: T.Text
  , build :: T.Text
  , kinds :: [T.Text]
  , bytes :: Int
  }
  deriving stock (Generic)
  deriving (ToJSON) via Generically Uploaded

data Receiving = Receiving
  { files :: [Received]
  , bytes :: Int
  }

symbols :: (Uploading env) => env -> SymbolsServer
symbols env = SymbolsServer{upload = uploading env}

uploading :: (Uploading env) => env -> Rpc.Context -> IO (Maybe UploadRequest) -> IO UploadResponse
uploading env context receive = do
  let uploads = getUploads env
  project <- authorised uploads context
  target <-
    receive >>= \case
      Just request | Just (UploadRequest'Target named) <- request ^. #maybe'part -> pure named
      _ -> Rpc.throwRpc Rpc.InvalidArgument "an upload starts by naming its project and build"
  unless (target ^. #project == project) (Rpc.throwRpc Rpc.PermissionDenied "the upload key belongs to another project")
  let build = target ^. #build
  when (T.null (T.strip build)) (Rpc.throwRpc Rpc.InvalidArgument "an upload names the build its symbols belong to")
  createDirectoryIfMissing True (uploads.directory </> "staging")
  withTempDirectory (uploads.directory </> "staging") "upload" \staging -> do
    received <- receiving uploads.maxBytes staging receive Receiving{files = [], bytes = 0}
    let grouped = Map.fromListWith (flip (<>)) [(file.kind, file :| []) | file <- received.files]
    indexed <- for (Map.toList grouped) (uncurry (indexing (getSymbolicator env) staging)) >>= either refuse pure . sequenceA
    now <- (getClock env).now
    stored <- storing env "symbols" (keep env Destination{directory = uploads.directory, project, build, staging} now indexed)
    for_ stored removePathForcibly
    _ <- storing env "regroup" (resymbolicate env project build)
    (getJournal env).write "symbols-uploaded" (toJSON Uploaded{project, build, kinds = fmap (\kept -> kindName kept.kind) indexed, bytes = received.bytes})
    pure (defMessage & #kinds .~ [defMessage & #kind .~ wireKind kind & #files .~ fromIntegral (NonEmpty.length files) | (kind, files) <- Map.toList grouped])

receiving :: Int -> FilePath -> IO (Maybe UploadRequest) -> Receiving -> IO Receiving
receiving cap staging receive state =
  receive >>= \case
    Nothing -> pure Receiving{files = reverse state.files, bytes = state.bytes}
    Just request -> case request ^. #maybe'part of
      Just (UploadRequest'File file) -> do
        kind <- maybe (Rpc.throwRpc Rpc.InvalidArgument "a symbol file names no kind") pure (kindOf (file ^. #kind))
        let name = safeName (file ^. #name)
            directory = staging </> T.unpack (kindName kind) </> "files"
            path = directory </> (show (length state.files) <> "-" <> T.unpack name)
        createDirectoryIfMissing True directory
        BS.writeFile path BS.empty
        receiving cap staging receive Receiving{files = Received{kind, name = file ^. #name, path} : state.files, bytes = state.bytes}
      Just (UploadRequest'Chunk chunk) -> case state.files of
        [] -> Rpc.throwRpc Rpc.InvalidArgument "a chunk arrived before any symbol file was named"
        current : _ -> do
          let total = state.bytes + BS.length chunk
          when (total > cap) (Rpc.throwRpc Rpc.ResourceExhausted ("the upload is larger than the " <> T.pack (show cap) <> " bytes the server accepts"))
          BS.appendFile current.path chunk
          receiving cap staging receive Receiving{files = state.files, bytes = total}
      Just (UploadRequest'Target _) -> Rpc.throwRpc Rpc.InvalidArgument "an upload names its project and build once"
      Nothing -> receiving cap staging receive state

kindOf :: Wire.SymbolKind -> Maybe SymbolKind
kindOf wire = lookup wire [(wireKind kind, kind) | kind <- enumerate]

wireKind :: SymbolKind -> Wire.SymbolKind
wireKind = \case
  DartSymbols -> Wire.SYMBOL_KIND_DART_SYMBOLS
  WebSourceMaps -> Wire.SYMBOL_KIND_WEB_SOURCE_MAPS
  R8Mapping -> Wire.SYMBOL_KIND_R8_MAPPING
  NdkSymbols -> Wire.SYMBOL_KIND_NDK_SYMBOLS
  Dsyms -> Wire.SYMBOL_KIND_DSYMS

refuse :: Unindexed -> IO a
refuse (Unindexed name failure) = case failure of
  Rejected reason -> Rpc.throwRpc Rpc.InvalidArgument (name <> ": " <> reason)
  Unreachable _ -> Rpc.throwRpc Rpc.Unavailable (describeSymbolicatorError failure)
