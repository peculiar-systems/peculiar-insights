module Main (main) where

import Data.Aeson (eitherDecodeFileStrict')
import Data.ByteString qualified as BS
import Data.Text qualified as T
import Data.Text.IO qualified as TIO
import Peculiar.Insights.Inventory (fromDescriptorSet, renderManifest, renderMarkdown)
import System.Environment (getArgs)
import System.Exit (exitFailure)
import System.IO (hPutStrLn, stderr)

main :: IO ()
main =
  getArgs >>= \case
    [descriptor, accessed, markdownOut, manifestOut] -> do
      bytes <- BS.readFile descriptor
      apis <- eitherDecodeFileStrict' accessed >>= either (failWith . T.pack) pure
      inventory <- either failWith pure (fromDescriptorSet bytes)
      TIO.writeFile markdownOut (renderMarkdown inventory)
      TIO.writeFile manifestOut (renderManifest inventory apis)
    _ -> failWith "usage: peculiar-insights-inventory <descriptor-set> <accessed-api.json> <markdown-out> <manifest-out>"

failWith :: T.Text -> IO a
failWith reason = hPutStrLn stderr (T.unpack reason) *> exitFailure
