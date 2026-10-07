module Peculiar.Insights.Upload.Options
  ( Options (..)
  , Server (..)
  , Scheme (..)
  , ServerError (..)
  , describeServerError
  , parseServer
  , options
  , kindFlag
  ) where

import Data.Text qualified as T
import Data.Text.Read (decimal)
import Options.Applicative
import Peculiar.Insights.Core.Enum (enumerate)
import Peculiar.Insights.Core.Symbols (SymbolKind (..), kindName)

kindFlag :: SymbolKind -> T.Text
kindFlag = T.replace "_" "-" . kindName

kindHelp :: SymbolKind -> T.Text
kindHelp = \case
  DartSymbols -> "A Dart symbols file, or the directory given to --split-debug-info"
  WebSourceMaps -> "A source map, or a directory holding the build's .map files"
  R8Mapping -> "The R8 mapping.txt of an Android build"
  NdkSymbols -> "An unstripped native library, or a directory holding them"
  Dsyms -> "A .dSYM bundle, or a directory holding them"

data Options = Options
  { server :: T.Text
  , project :: T.Text
  , build :: T.Text
  , keyFile :: FilePath
  , files :: [(SymbolKind, FilePath)]
  }
  deriving stock (Eq, Show)

options :: ParserInfo Options
options =
  info
    (parser <**> helper)
    (fullDesc <> progDesc "Upload a build's symbols to a Peculiar Insights server so its crash reports are symbolicated")
 where
  parser = do
    server <- strOption (long "server" <> metavar "URL" <> help "The server, such as https://insights.example.org")
    project <- strOption (long "project" <> metavar "SLUG" <> help "The project the build belongs to")
    build <- strOption (long "build" <> metavar "BUILD" <> help "The build the symbols belong to, as the app reports it")
    keyFile <- strOption (long "key-file" <> metavar "PATH" <> help "A file holding the project's upload key")
    files <- concat <$> traverse kindFiles enumerate
    pure Options{server, project, build, keyFile, files}
  kindFiles kind = many ((kind,) <$> strOption (long (T.unpack (kindFlag kind)) <> metavar "PATH" <> help (T.unpack (kindHelp kind))))

data Scheme = Plain | Secure
  deriving stock (Eq, Show)

data Server = Server
  { scheme :: Scheme
  , host :: T.Text
  , port :: Int
  }
  deriving stock (Eq, Show)

data ServerError
  = UnknownScheme T.Text
  | NoHost T.Text
  | BadPort T.Text
  deriving stock (Eq, Show)

describeServerError :: ServerError -> T.Text
describeServerError = \case
  UnknownScheme url -> url <> " is neither an http:// nor an https:// URL"
  NoHost url -> url <> " names no host"
  BadPort url -> url <> " names a port that is not a number between 1 and 65535"

parseServer :: T.Text -> Either ServerError Server
parseServer url = do
  (scheme, rest) <- case T.breakOn "://" url of
    ("https", rest) -> Right (Secure, T.drop 3 rest)
    ("http", rest) -> Right (Plain, T.drop 3 rest)
    _ -> Left (UnknownScheme url)
  let authority = T.takeWhile (/= '/') rest
      (bracketed, afterBracket) = T.breakOn "]" authority
      (host, portText)
        | T.isPrefixOf "[" authority = (T.drop 1 bracketed, T.drop 1 afterBracket)
        | otherwise = T.breakOn ":" authority
  port <- case T.stripPrefix ":" portText of
    Nothing | T.null portText -> Right (defaultPort scheme)
    Just digits | Right (number, "") <- decimal digits, number >= 1, number <= 65535 -> Right number
    _ -> Left (BadPort url)
  if T.null host then Left (NoHost url) else Right Server{scheme, host, port}
 where
  defaultPort = \case
    Plain -> 80
    Secure -> 443
