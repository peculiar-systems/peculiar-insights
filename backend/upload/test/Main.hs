module Main (main) where

import Control.Monad (unless)
import Control.Monad.IO.Class (liftIO)
import Hedgehog hiding (collect)
import Peculiar.Insights.Core.Symbols (SymbolKind (..))
import Peculiar.Insights.Upload (Upload (..), UploadError (..), collect)
import Peculiar.Insights.Upload.Options (Scheme (..), Server (..), ServerError (..), parseServer)
import System.Directory (createDirectoryIfMissing)
import System.Exit (exitFailure)
import System.FilePath ((</>))
import System.IO.Temp (withSystemTempDirectory)

main :: IO ()
main = do
  passed <-
    checkSequential
      ( Group
          "Upload"
          [ ("server URLs name scheme, host and port", withTests 1 servers)
          , ("directories contribute the files of their kind", withTests 1 directories)
          ]
      )
  unless passed exitFailure

servers :: Property
servers = property do
  parseServer "https://insights.example.org" === Right Server{scheme = Secure, host = "insights.example.org", port = 443}
  parseServer "http://127.0.0.1:50051/" === Right Server{scheme = Plain, host = "127.0.0.1", port = 50051}
  parseServer "https://[::1]:8443" === Right Server{scheme = Secure, host = "::1", port = 8443}
  parseServer "ftp://insights.example.org" === Left (UnknownScheme "ftp://insights.example.org")
  parseServer "http://insights.example.org:0" === Left (BadPort "http://insights.example.org:0")
  parseServer "https://:443" === Left (NoHost "https://:443")

directories :: Property
directories = property do
  (found, expected) <- liftIO $ withSystemTempDirectory "upload" \root -> do
    let symbols = root </> "symbols"
        bundle = root </> "Runner.app.dSYM"
        dwarf = bundle </> "Contents" </> "Resources" </> "DWARF"
        bare = root </> "bare"
        absent = root </> "absent.txt"
    mapM_ (createDirectoryIfMissing True) [symbols, dwarf, bare]
    writeFile (symbols </> "app.android-arm64.symbols") "elf"
    writeFile (symbols </> "notes.txt") "other"
    writeFile (dwarf </> "Runner") "macho"
    writeFile (bundle </> "Contents" </> "Info.plist") "plist"
    found <- traverse (uncurry collect) [(DartSymbols, symbols), (Dsyms, bundle), (NdkSymbols, bare), (R8Mapping, absent)]
    pure
      ( found
      ,
        [ Right [Upload{kind = DartSymbols, path = symbols </> "app.android-arm64.symbols"}]
        , Right [Upload{kind = Dsyms, path = dwarf </> "Runner"}]
        , Left (NothingFound NdkSymbols bare)
        , Left (Missing absent)
        ]
      )
  found === expected
