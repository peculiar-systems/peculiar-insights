module Peculiar.Insights.Server.Config
  ( Loaded (..)
  , LoadError (..)
  , load
  , inspect
  , describeLoadError
  ) where

import Control.Exception (IOException, try)
import Data.Aeson (eitherDecodeFileStrict')
import Data.ByteString qualified as BS
import Data.ByteString.Char8 qualified as BC
import Data.Text qualified as T
import Data.Traversable (for)
import Peculiar.Insights.Core.Config (Config (..), ConfigError, Project (..), Symbols (..), UploadKey (..), checkConfig, describeConfigError)

data Loaded = Loaded
  { config :: Config
  , keys :: [(BS.ByteString, Project)]
  , uploadKeys :: [(BS.ByteString, T.Text)]
  }

data LoadError
  = Unreadable FilePath T.Text
  | Malformed T.Text
  | Invalid ConfigError
  | KeyUnreadable FilePath T.Text
  | KeyEmpty FilePath
  deriving stock (Eq, Show)

describeLoadError :: LoadError -> T.Text
describeLoadError = \case
  Unreadable path reason -> "cannot read " <> T.pack path <> ": " <> reason
  Malformed reason -> "the configuration is malformed: " <> reason
  Invalid failure -> "the configuration is invalid: " <> describeConfigError failure
  KeyUnreadable path reason -> "cannot read the key file " <> T.pack path <> ": " <> reason
  KeyEmpty path -> "the key file " <> T.pack path <> " is empty"

inspect :: FilePath -> IO (Either LoadError Config)
inspect path =
  try @IOException (eitherDecodeFileStrict' path) >>= \case
    Left failure -> pure (Left (Unreadable path (T.pack (show failure))))
    Right (Left reason) -> pure (Left (Malformed (T.pack reason)))
    Right (Right config) -> pure (either (Left . Invalid) (const (Right config)) (checkConfig config))

load :: FilePath -> IO (Either LoadError Loaded)
load path =
  inspect path >>= \case
    Left failure -> pure (Left failure)
    Right config -> do
      keys <- for config.projects \project -> fmap (,project) <$> readKey project.keyFile
      uploadKeys <- for config.symbols.uploadKeys \upload -> fmap (,upload.project) <$> readKey upload.keyFile
      pure (Loaded config <$> sequence keys <*> sequence uploadKeys)

readKey :: FilePath -> IO (Either LoadError BS.ByteString)
readKey path =
  try @IOException (BS.readFile path) >>= \case
    Left failure -> pure (Left (KeyUnreadable path (T.pack (show failure))))
    Right raw ->
      let key = BC.strip raw
       in pure if BS.null key then Left (KeyEmpty path) else Right key
