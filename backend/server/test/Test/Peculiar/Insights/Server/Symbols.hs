{-# LANGUAGE TemplateHaskell #-}

module Test.Peculiar.Insights.Server.Symbols
  ( tests
  ) where

import Control.Exception (try)
import Control.Monad (void)
import Control.Monad.IO.Class (liftIO)
import Data.Aeson (eitherDecodeStrict)
import Data.ByteString qualified as BS
import Data.FileEmbed (embedFile)
import Data.Int (Int64)
import Data.Map.Strict qualified as Map
import Data.ProtoLens (defMessage)
import Data.ProtoLens.Labels ()
import Data.String (fromString)
import Data.Text qualified as T
import Data.Text.IO qualified as TIO
import Data.Time (addUTCTime, getCurrentTime, nominalDay)
import Data.Word (Word32)
import Database.PostgreSQL.Simple (query_)
import Hedgehog
import Lens.Family2 ((&), (.~))
import Peculiar.Insights.Core.Item (Frame (..))
import Peculiar.Insights.Server.Symbols (SymbolsClient (..))
import Peculiar.Rpc qualified as Rpc
import Proto.Peculiar.Insights.V1.Common (Platform (..))
import Proto.Peculiar.Insights.V1.Ingest (Outcome (..))
import System.Directory (doesDirectoryExist)
import System.Exit (ExitCode (..))
import System.FilePath ((</>))
import Test.Peculiar.Insights.Server.Dashboard (Binding (..), Bindings (..), Panel (..), PanelQuery (..), Target (..), TimeRange (..), interpolate, panelQueries)
import Test.Peculiar.Insights.Server.SymbolFixtures
import Test.Peculiar.Insights.Server.Traces

issueDashboard :: BS.ByteString
issueDashboard = $(embedFile "../../grafana/dashboards/issue.json")

tests :: Suite -> Group
tests suite =
  Group
    "Symbols"
    [ ("an upload with another project's key or none is refused", withTests 1 (refused suite))
    , ("a Flutter AOT report is stored with symbolicated frames, shown on the issue detail dashboard", withTests 1 (dartFrames suite))
    , ("a Flutter web report is symbolicated through its build's source maps", withTests 1 (webFrames suite))
    , ("an Android report's native and JVM frames are symbolicated from NDK symbols and the R8 mapping", withTests 1 (androidFrames suite))
    , ("an iOS report's native frames are symbolicated from its dSYMs", withTests 1 (iosFrames suite))
    , ("a later upload adds the kinds it carries and replaces those the build had", withTests 1 (replacedKinds suite))
    , ("an upload over the size cap is refused", withTests 1 (capped suite))
    ]

refused :: Suite -> Property
refused suite = property do
  (stranger, anonymous, own, kinds) <- liftIO $ serving suite roomy \port -> do
    stranger <- uploading suite port notesKey "auth-1" [("dart-symbols", "dart/app.symbols")]
    anonymous <- try @Rpc.RpcError $ Rpc.withNativeClient Rpc.Plaintext "127.0.0.1" port \transport -> do
      let client = Rpc.client Rpc.defaultOptions transport :: SymbolsClient
      client.upload \send -> send (defMessage & #target .~ (defMessage & #project .~ "shop" & #build .~ "auth-1"))
    own <- uploading suite port shopKey "auth-1" [("dart-symbols", "dart/app.symbols")]
    kinds <- stored suite "auth-1"
    pure (fst stranger, void anonymous, fst own, kinds)
  stranger /== ExitSuccess
  either (\refusal -> refusal.status.code) (const Rpc.Ok) anonymous === Rpc.Unauthenticated
  own === ExitSuccess
  kinds === ["dart_symbols"]

dartFrames :: Suite -> Property
dartFrames suite = property do
  frames <- liftIO (dartTrace suite)
  (uploaded, outcomes, symbolicated, shown) <- liftIO $ serving suite roomy \port -> do
    uploaded <- uploading suite port shopKey "dart-1" [("dart-symbols", "dart/app.symbols")]
    item <- crashOf (crashId 1) "dart-1" PLATFORM_ANDROID "StateError" frames
    outcomes <- publishing port [item]
    symbolicated <- framesOf suite 1
    issue <- issueOf suite 1
    shown <- framePanel suite issue
    pure (fst uploaded, outcomes, symbolicated, shown)
  uploaded === ExitSuccess
  outcomes === [OUTCOME_ACCEPTED]
  take 1 (fmap located symbolicated) === [("explode", "main.dart", 3)]
  take 1 shown === [("explode", "main.dart", 3)]

framePanel :: Suite -> Int64 -> IO [(T.Text, T.Text, Word32)]
framePanel suite issue = case eitherDecodeStrict issueDashboard of
  Left _ -> pure []
  Right dashboard -> case [query' | query' <- panelQueries dashboard, query'.panel.title == "Stack frames of the latest crash"] of
    [] -> pure []
    found : _ -> do
      now <- getCurrentTime
      let single value = Binding{values = [value], multiple = False}
          bindings =
            Bindings
              { range = TimeRange{from = addUTCTime (negate nominalDay) now, to = addUTCTime nominalDay now}
              , intervalSeconds = 60
              , variables = Map.fromList [("project", single "shop"), ("environment", single "test"), ("issue", single (T.pack (show issue)))]
              }
      case interpolate bindings found.target.rawSql of
        Left _ -> pure []
        Right sql -> withConnection suite \connection -> do
          rows <- query_ connection (fromString (T.unpack sql))
          pure [(function, T.takeWhileEnd (/= '/') file, fromIntegral line) | (_ :: Int64, _ :: Bool, _ :: T.Text, function, file, line :: Int, _ :: Int) <- rows]

webFrames :: Suite -> Property
webFrames suite = property do
  frames <- liftIO (webTrace suite)
  symbolicated <- liftIO $ serving suite roomy \port -> do
    void (uploading suite port shopKey "web-1" [("web-source-maps", "web/main.js.map")])
    item <- crashOf (crashId 2) "web-1" PLATFORM_WEB "StateError" frames
    void (publishing port [item])
    framesOf suite 2
  assert (("explode", "main.dart", 3) `elem` fmap located symbolicated)

androidFrames :: Suite -> Property
androidFrames suite = property do
  addresses <- liftIO (symbolAddresses suite "ndk/symbols.txt")
  buildId <- liftIO (T.strip <$> TIO.readFile (suite.fixtures.root </> "ndk" </> "build-id.txt"))
  let jvm = Frame{moduleName = "a.a", function = "a", file = "SourceFile", line = 3, column = 0, inApp = True, instructionAddress = Nothing, image = Nothing}
      frames = nativeFrames "libcrash.so" buildId 0x7a00000000 addresses <> [jvm]
  symbolicated <- liftIO $ serving suite roomy \port -> do
    void (uploading suite port shopKey "android-1" [("ndk-symbols", "ndk/libcrash.so"), ("r8-mapping", "r8/mapping.txt")])
    item <- crashOf (crashId 3) "android-1" PLATFORM_ANDROID "SIGSEGV" frames
    void (publishing port [item])
    framesOf suite 3
  fmap (\frame -> (frame.moduleName, frame.function, T.takeWhileEnd (/= '/') frame.file)) symbolicated
    === [("libcrash.so", "fault_here", "crash.c"), ("libcrash.so", "entry", "crash.c"), ("com.example.shop.Checkout", "pay", "Checkout.java")]
  fmap (.line) (drop 2 symbolicated) === [21]

iosFrames :: Suite -> Property
iosFrames suite = property do
  addresses <- liftIO (symbolAddresses suite "ios/symbols.txt")
  uuid <- liftIO (T.strip <$> TIO.readFile (suite.fixtures.root </> "ios" </> "uuid.txt"))
  symbolicated <- liftIO $ serving suite roomy \port -> do
    void (uploading suite port shopKey "ios-1" [("dsyms", "ios/libcrash.dylib.dSYM")])
    item <- crashOf (crashId 4) "ios-1" PLATFORM_IOS "SIGSEGV" (nativeFrames "libcrash.dylib" uuid 0x102340000 addresses)
    void (publishing port [item])
    framesOf suite 4
  fmap (\frame -> (frame.function, T.takeWhileEnd (/= '/') frame.file)) symbolicated === [("fault_here", "crash.c"), ("entry", "crash.c")]

replacedKinds :: Suite -> Property
replacedKinds suite = property do
  (afterDart, afterMapping, firstDirectory, secondDirectory, firstGone) <- liftIO $ serving suite roomy \port -> do
    void (uploading suite port shopKey "multi-1" [("dart-symbols", "dart/app.symbols")])
    afterDart <- stored suite "multi-1"
    firstDirectory <- kindDirectory suite "multi-1" "dart_symbols"
    void (uploading suite port shopKey "multi-1" [("r8-mapping", "r8/mapping.txt")])
    afterMapping <- stored suite "multi-1"
    void (uploading suite port shopKey "multi-1" [("dart-symbols", "dart/app.symbols")])
    secondDirectory <- kindDirectory suite "multi-1" "dart_symbols"
    firstGone <- not <$> maybe (pure False) doesDirectoryExist firstDirectory
    pure (afterDart, afterMapping, firstDirectory, secondDirectory, firstGone)
  afterDart === ["dart_symbols"]
  afterMapping === ["dart_symbols", "r8_mapping"]
  firstDirectory /== secondDirectory
  firstGone === True

capped :: Suite -> Property
capped suite = property do
  (code, kinds) <- liftIO $ serving suite 4096 \port -> do
    (code, _) <- uploading suite port shopKey "capped-1" [("dart-symbols", "dart/app.symbols")]
    kinds <- stored suite "capped-1"
    pure (code, kinds)
  code /== ExitSuccess
  kinds === []
