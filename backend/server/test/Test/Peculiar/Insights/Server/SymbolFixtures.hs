module Test.Peculiar.Insights.Server.SymbolFixtures
  ( Fixtures (..)
  , Suite (..)
  , suiteOf
  , shopKey
  , notesKey
  , serving
  , roomy
  , uploading
  , stored
  , withConnection
  , crashOf
  , publishing
  , crashId
  , framesOf
  , issueOf
  , located
  , issueExists
  , issueTitle
  , issueState
  , kindDirectory
  ) where

import Control.Exception (bracket)
import Data.Aeson qualified as Aeson
import Data.ByteString qualified as BS
import Data.Int (Int64)
import Data.ProtoLens (defMessage)
import Data.ProtoLens.Labels ()
import Data.Text qualified as T
import Data.Text.Encoding qualified as TE
import Data.Time (getCurrentTime)
import Data.Time.Clock.POSIX (utcTimeToPOSIXSeconds)
import Data.UUID.Types qualified as UUID
import Data.Word (Word32)
import Database.PostgreSQL.Simple (Connection, Only (..), close, connectPostgreSQL, query)
import Lens.Family2 ((&), (.~), (^.))
import Peculiar.Insights.Core.Item (Frame (..))
import Peculiar.Insights.Server.Api (IngestClient (..))
import Peculiar.Insights.Server.Db (Db)
import Peculiar.Insights.Server.Symbolicator (Symbolicator)
import Peculiar.Insights.Server.Uploads (mkUploads)
import Proto.Peculiar.Insights.V1.Common (Platform)
import Proto.Peculiar.Insights.V1.Ingest (Outcome)
import Proto.Peculiar.Insights.V1.Ingest qualified as P
import System.Environment (getEnv)
import System.Exit (ExitCode)
import System.FilePath ((</>))
import System.Process (readProcessWithExitCode)
import Test.Peculiar.Insights.Server.Frames (protoFrame)
import Test.Peculiar.Insights.Server.Harness (granted, remote, request, withSymbols)

data Fixtures = Fixtures
  { root :: FilePath
  , uploader :: FilePath
  , keys :: FilePath
  }

data Suite = Suite
  { conninfo :: T.Text
  , db :: Db
  , symbolicator :: Symbolicator
  , fixtures :: Fixtures
  , symbols :: FilePath
  }

suiteOf :: T.Text -> Db -> Symbolicator -> FilePath -> IO Suite
suiteOf conninfo db symbolicator scratch = do
  root <- getEnv "PECULIAR_INSIGHTS_FIXTURES"
  uploader <- getEnv "PECULIAR_INSIGHTS_UPLOAD"
  pure Suite{conninfo, db, symbolicator, fixtures = Fixtures{root, uploader, keys = scratch </> "keys"}, symbols = scratch </> "symbols"}

shopKey :: T.Text
shopKey = "shop-upload-key"

notesKey :: T.Text
notesKey = "notes-upload-key"

serving :: Suite -> Int -> (Int -> IO a) -> IO a
serving suite cap use = do
  BS.writeFile (suite.fixtures.keys <> "-shop") (TE.encodeUtf8 shopKey)
  BS.writeFile (suite.fixtures.keys <> "-notes") (TE.encodeUtf8 notesKey)
  withSymbols suite.db suite.symbolicator (mkUploads suite.symbols cap [(TE.encodeUtf8 shopKey, "shop"), (TE.encodeUtf8 notesKey, "notes")]) use

roomy :: Int
roomy = 64 * 1024 * 1024

uploading :: Suite -> Int -> T.Text -> T.Text -> [(T.Text, FilePath)] -> IO (ExitCode, T.Text)
uploading suite port key build files = do
  let keyFile = suite.fixtures.keys <> "-" <> (if key == shopKey then "shop" else "notes")
      arguments =
        ["--server", "http://127.0.0.1:" <> show port, "--project", "shop", "--build", T.unpack build, "--key-file", keyFile]
          <> concat [["--" <> T.unpack flag, suite.fixtures.root </> path] | (flag, path) <- files]
  (code, out, err) <- readProcessWithExitCode suite.fixtures.uploader arguments ""
  pure (code, T.pack (out <> err))

stored :: Suite -> T.Text -> IO [T.Text]
stored suite build = withConnection suite \connection ->
  fmap fromOnly <$> query connection "SELECT kind.kind FROM symbol_kind kind JOIN symbol_build build ON build.id = kind.build_id WHERE build.project = 'shop' AND build.build = ? ORDER BY kind.kind" (Only build)

withConnection :: Suite -> (Connection -> IO a) -> IO a
withConnection suite = bracket (connectPostgreSQL (TE.encodeUtf8 suite.conninfo)) close

crashOf :: T.Text -> T.Text -> Platform -> T.Text -> [Frame] -> IO P.Item
crashOf identifier build platform exceptionType frames = do
  now <- getCurrentTime
  let stamp = defMessage & #seconds .~ floor (utcTimeToPOSIXSeconds now)
      subject = defMessage & #deviceId .~ "symbols-" <> build & #sessionId .~ "symbols-" <> build
      context = defMessage & #sdkName .~ "peculiar_insights_flutter" & #appBuild .~ build & #platform .~ platform
      crash = defMessage & #id .~ identifier & #time .~ stamp & #subject .~ subject & #context .~ context & #exceptionType .~ exceptionType & #message .~ "boom" & #fatal .~ True & #frames .~ fmap protoFrame frames
  pure (defMessage & #crashReport .~ crash)

publishing :: Int -> [P.Item] -> IO [Outcome]
publishing port items = do
  api <- remote port (Just "test-key")
  response <- request granted items >>= api.publish
  pure (fmap (^. #outcome) (response ^. #outcomes))

crashId :: Word32 -> T.Text
crashId n = UUID.toText (UUID.fromWords 0x5ab 0 0 n)

framesOf :: Suite -> Word32 -> IO [Frame]
framesOf suite n = withConnection suite \connection -> do
  rows <- query connection "SELECT frames FROM crash WHERE id = ?" (Only (UUID.fromWords 0x5ab 0 0 n))
  pure case rows of
    [Only value] | Aeson.Success frames <- Aeson.fromJSON value -> frames
    _ -> []

issueOf :: Suite -> Word32 -> IO Int64
issueOf suite n = withConnection suite \connection -> do
  rows <- query connection "SELECT issue_id FROM crash WHERE id = ?" (Only (UUID.fromWords 0x5ab 0 0 n))
  pure case rows of
    [Only issue] -> issue
    _ -> -1

located :: Frame -> (T.Text, T.Text, Word32)
located frame = (frame.function, T.takeWhileEnd (/= '/') frame.file, frame.line)

issueExists :: Suite -> Int64 -> IO Bool
issueExists suite issue = withConnection suite \connection -> do
  rows <- query connection "SELECT count(*) FROM issue WHERE id = ?" (Only issue)
  pure (rows == [Only (1 :: Int64)])

issueTitle :: Suite -> Int64 -> IO (Maybe T.Text)
issueTitle suite issue = withConnection suite \connection -> do
  rows <- query connection "SELECT title FROM issue WHERE id = ?" (Only issue)
  pure case rows of
    [Only title] -> Just title
    _ -> Nothing

issueState :: Suite -> Int64 -> IO (Maybe T.Text)
issueState suite issue = withConnection suite \connection -> do
  rows <- query connection "SELECT state FROM issue WHERE id = ?" (Only issue)
  pure case rows of
    [Only state] -> Just state
    _ -> Nothing

kindDirectory :: Suite -> T.Text -> T.Text -> IO (Maybe FilePath)
kindDirectory suite build kind = withConnection suite \connection -> do
  rows <- query connection "SELECT kind.directory FROM symbol_kind kind JOIN symbol_build build ON build.id = kind.build_id WHERE build.build = ? AND kind.kind = ?" (build, kind)
  pure case rows of
    [Only directory] -> Just (T.unpack directory)
    _ -> Nothing
