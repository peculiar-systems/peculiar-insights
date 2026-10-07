module Test.Peculiar.Insights.Server.Traces
  ( dartTrace
  , webTrace
  , symbolAddresses
  , nativeFrames
  ) where

import Data.List (find)
import Data.Map.Strict qualified as Map
import Data.Maybe (mapMaybe)
import Data.Text qualified as T
import Data.Text.IO qualified as TIO
import Data.Text.Read (decimal, hexadecimal)
import Data.Word (Word64)
import Peculiar.Insights.Core.Item (Frame (..), Image (..))
import System.FilePath ((</>))
import Test.Peculiar.Insights.Server.SymbolFixtures (Fixtures (..), Suite (..))

dartTrace :: Suite -> IO [Frame]
dartTrace suite = do
  trace <- TIO.readFile (suite.fixtures.root </> "dart" </> "trace.txt")
  let lines' = fmap T.strip (T.lines trace)
      header key = find (key `T.isPrefixOf`) (concatMap (T.splitOn ", ") lines')
      buildId = maybe "" (T.dropAround (== '\'') . T.strip . T.drop 9) (header "build_id:")
      instructions = maybe 0 (hex . T.strip . T.drop 21) (header "isolate_instructions:")
  pure (mapMaybe (aotFrame buildId instructions) lines')
 where
  aotFrame buildId instructions line = case T.words line of
    _ : "abs" : _ : "virt" : virtual : location : _ ->
      Just
        Frame
          { moduleName = ""
          , function = location
          , file = ""
          , line = 0
          , column = 0
          , inApp = True
          , instructionAddress = Just (hex virtual)
          , image = Just Image{name = "_kDartIsolateSnapshotInstructions", identifier = buildId, loadAddress = instructions}
          }
    _ -> Nothing

hex :: T.Text -> Word64
hex text = either (const 0) fst (hexadecimal text)

webTrace :: Suite -> IO [Frame]
webTrace suite = do
  trace <- TIO.readFile (suite.fixtures.root </> "web" </> "trace.txt")
  pure (mapMaybe (webFrame . T.strip) (T.lines trace))
 where
  webFrame line = do
    rest <- T.stripPrefix "at " line
    let (function, located) = T.breakOn " (" rest
    location <- T.stripSuffix ")" (T.drop 2 located)
    case reverse (T.splitOn ":" location) of
      column : row : path
        | Right (c, "") <- decimal column
        , Right (r, "") <- decimal row ->
            let file = T.intercalate ":" (reverse path)
             in Just Frame{moduleName = "", function, file, line = r, column = c, inApp = True, instructionAddress = Nothing, image = Nothing}
      _ -> Nothing

symbolAddresses :: Suite -> FilePath -> IO (Map.Map T.Text Word64)
symbolAddresses suite path = do
  listed <- TIO.readFile (suite.fixtures.root </> path)
  pure (Map.fromList [(name, hex address) | [name, address] <- fmap T.words (T.lines listed)])

nativeFrames :: T.Text -> T.Text -> Word64 -> Map.Map T.Text Word64 -> [Frame]
nativeFrames library identifier base addresses =
  [ native (Map.findWithDefault 0 "fault_here" addresses + 4)
  , native (Map.findWithDefault 0 "entry" addresses + 12)
  ]
 where
  native offset =
    Frame
      { moduleName = ""
      , function = ""
      , file = ""
      , line = 0
      , column = 0
      , inApp = True
      , instructionAddress = Just (base + offset)
      , image = Just Image{name = library, identifier, loadAddress = base}
      }
