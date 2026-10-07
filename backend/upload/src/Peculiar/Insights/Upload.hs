{-# LANGUAGE TemplateHaskell #-}

module Peculiar.Insights.Upload
  ( main'
  , UploadError (..)
  , describeUploadError
  , Upload (..)
  , collect
  , upload
  ) where

import Control.Exception (IOException, try)
import Control.Monad (unless)
import Data.ByteString qualified as BS
import Data.ByteString.Char8 qualified as BC
import Data.Foldable (for_)
import Data.List (isInfixOf, isSuffixOf, sort)
import Data.ProtoLens (defMessage)
import Data.ProtoLens.Labels ()
import Data.Text qualified as T
import Data.Text.IO qualified as TIO
import Data.Traversable (for)
import Lens.Family2 ((&), (.~), (^.))
import Options.Applicative (execParser)
import Peculiar.Insights.Core.Enum (enumerate)
import Peculiar.Insights.Core.Symbols (SymbolKind (..))
import Peculiar.Insights.Upload.Options
import Peculiar.Rpc.Client qualified as Rpc
import Proto.Peculiar.Insights.V1.Symbols qualified as Wire
import System.Directory (doesDirectoryExist, doesFileExist, listDirectory)
import System.Exit (exitFailure)
import System.FilePath (splitDirectories, takeFileName, (</>))
import System.IO (IOMode (ReadMode), hPutStrLn, stderr, withBinaryFile)

Rpc.deriveClient ''Wire.Symbols

data UploadError
  = BadServer ServerError
  | KeyUnreadable FilePath T.Text
  | KeyEmpty FilePath
  | Missing FilePath
  | NothingFound SymbolKind FilePath
  | NothingToUpload
  | Unreadable FilePath T.Text
  | Refused T.Text
  deriving stock (Eq, Show)

describeUploadError :: UploadError -> T.Text
describeUploadError = \case
  BadServer failure -> describeServerError failure
  KeyUnreadable path reason -> "cannot read the upload key file " <> T.pack path <> ": " <> reason
  KeyEmpty path -> "the upload key file " <> T.pack path <> " is empty"
  Missing path -> T.pack path <> " does not exist"
  NothingFound kind path -> T.pack path <> " holds no files for --" <> kindFlag kind
  NothingToUpload -> "no symbol files were named"
  Unreadable path reason -> "cannot read " <> T.pack path <> ": " <> reason
  Refused reason -> "the server refused the upload: " <> reason

data Upload = Upload
  { kind :: SymbolKind
  , path :: FilePath
  }
  deriving stock (Eq, Show)

main' :: IO ()
main' = do
  given <- execParser options
  upload given >>= \case
    Left failure -> hPutStrLn stderr (T.unpack (describeUploadError failure)) *> exitFailure
    Right stored -> for_ stored \(kind, count) -> TIO.putStrLn (kindFlag kind <> ": " <> T.pack (show count) <> " files stored")

upload :: Options -> IO (Either UploadError [(SymbolKind, Int)])
upload given = case parseServer given.server of
  Left failure -> pure (Left (BadServer failure))
  Right server ->
    readKey given.keyFile >>= \case
      Left failure -> pure (Left failure)
      Right key ->
        traverse (uncurry collect) given.files >>= \collected -> case concat <$> sequenceA collected of
          Left failure -> pure (Left failure)
          Right [] -> pure (Left NothingToUpload)
          Right found -> sending server key given found

sending :: Server -> BS.ByteString -> Options -> [Upload] -> IO (Either UploadError [(SymbolKind, Int)])
sending server key given found = do
  let security = case server.scheme of
        Plain -> Rpc.Plaintext
        Secure -> Rpc.Secure Rpc.systemTls
      callOptions = Rpc.defaultOptions{Rpc.deadline = Just (Rpc.seconds 3600), Rpc.requestMetadata = Rpc.header "authorization" ("Bearer " <> key)}
  outcome <- try @Rpc.RpcError $ Rpc.withNativeClient security server.host server.port \transport -> do
    let remote = Rpc.client callOptions transport :: SymbolsClient
    remote.upload \send -> do
      send (defMessage & #target .~ (defMessage & #project .~ given.project & #build .~ given.build))
      for_ found \file -> do
        send (defMessage & #file .~ (defMessage & #kind .~ wireKind file.kind & #name .~ T.pack (takeFileName file.path)))
        withBinaryFile file.path ReadMode \handle ->
          let loop = do
                chunk <- BS.hGetSome handle chunkSize
                unless (BS.null chunk) (send (defMessage & #chunk .~ chunk) *> loop)
           in loop
  pure case outcome of
    Left failure -> Left (Refused failure.status.message)
    Right response -> Right [(kind, fromIntegral (stored ^. #files)) | stored <- response ^. #kinds, Just kind <- [kindOf (stored ^. #kind)]]

chunkSize :: Int
chunkSize = 1024 * 1024

wireKind :: SymbolKind -> Wire.SymbolKind
wireKind = \case
  DartSymbols -> Wire.SYMBOL_KIND_DART_SYMBOLS
  WebSourceMaps -> Wire.SYMBOL_KIND_WEB_SOURCE_MAPS
  R8Mapping -> Wire.SYMBOL_KIND_R8_MAPPING
  NdkSymbols -> Wire.SYMBOL_KIND_NDK_SYMBOLS
  Dsyms -> Wire.SYMBOL_KIND_DSYMS

kindOf :: Wire.SymbolKind -> Maybe SymbolKind
kindOf wire = lookup wire [(wireKind kind, kind) | kind <- enumerate]

collect :: SymbolKind -> FilePath -> IO (Either UploadError [Upload])
collect kind path = do
  isFile <- doesFileExist path
  isDirectory <- doesDirectoryExist path
  if
    | isFile -> pure (Right [Upload{kind, path}])
    | isDirectory -> do
        listed <- try @IOException (filesUnder path)
        pure case listed of
          Left failure -> Left (Unreadable path (T.pack (show failure)))
          Right files -> case [Upload{kind, path = file} | file <- files, belongs kind file] of
            [] -> Left (NothingFound kind path)
            chosen -> Right chosen
    | otherwise -> pure (Left (Missing path))

belongs :: SymbolKind -> FilePath -> Bool
belongs kind file = case kind of
  DartSymbols -> ".symbols" `isSuffixOf` file
  WebSourceMaps -> ".map" `isSuffixOf` file
  R8Mapping -> takeFileName file == "mapping.txt"
  NdkSymbols -> ".so" `isSuffixOf` file
  Dsyms -> ["Contents", "Resources", "DWARF"] `isInfixOf` splitDirectories file

filesUnder :: FilePath -> IO [FilePath]
filesUnder directory = do
  names <- sort <$> listDirectory directory
  concat <$> for names \name -> do
    let path = directory </> name
    nested <- doesDirectoryExist path
    if nested then filesUnder path else pure [path]

readKey :: FilePath -> IO (Either UploadError BS.ByteString)
readKey path =
  try @IOException (BS.readFile path) >>= \case
    Left failure -> pure (Left (KeyUnreadable path (T.pack (show failure))))
    Right raw ->
      let key = BC.strip raw
       in pure if BS.null key then Left (KeyEmpty path) else Right key
