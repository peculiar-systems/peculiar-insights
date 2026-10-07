module Test.Peculiar.Insights.Core.Symbols
  ( tests
  ) where

import Data.Text qualified as T
import Data.Time (UTCTime (..), addUTCTime, fromGregorian)
import Data.Word (Word32, Word64)
import Hedgehog
import Hedgehog.Gen qualified as Gen
import Hedgehog.Range qualified as Range
import Peculiar.Insights.Core.Enum (enumerate)
import Peculiar.Insights.Core.Issue (IssueState (..))
import Peculiar.Insights.Core.Item (Frame (..), Image (..), Platform (..))
import Peculiar.Insights.Core.Symbols

tests :: Group
tests =
  Group
    "Symbols"
    [ ("every kind reads back from its name", withTests 1 kindNames)
    , ("identifiers match whatever their case and dashes", withTests 1 identifiers)
    , ("a script is named by the last segment of its URL", withTests 1 scripts)
    , ("frames find the file that answers them", withTests 1 lookups)
    , ("resolved frames take the symbol's place and keep the raw frame's", withTests 1 resolved)
    , ("a regrouped issue takes a shared state and opens on differing ones", inherited)
    , ("the longest retention is unbounded when any environment keeps forever", withTests 1 retentions)
    , ("symbols expire only without reports, after a report or the longest retention", expiry)
    ]

kindNames :: Property
kindNames = property do
  fmap (kindFromName . kindName) enumerate === fmap Just (enumerate :: [SymbolKind])

identifiers :: Property
identifiers = property do
  normalizeIdentifier "4C4C4457-5555-3144-A16B-A19127EE0BFA" === "4c4c445755553144a16ba19127ee0bfa"
  normalizeIdentifier "a923e09728b440f0" === "a923e09728b440f0"

scripts :: Property
scripts = property do
  scriptName "https://shop.example.org/app/main.dart.js?v=3#top" === "main.dart.js"
  scriptName "/build/work/main.js" === "main.js"
  scriptName "main.js" === "main.js"

symbols :: Available
symbols =
  available
    [ Entry{kind = DartSymbols, identifier = "ABCDEF", path = "/s/dart"}
    , Entry{kind = NdkSymbols, identifier = "0011aa", path = "/s/ndk"}
    , Entry{kind = Dsyms, identifier = "4C4C4457-5555", path = "/s/dsym"}
    , Entry{kind = R8Mapping, identifier = "", path = "/s/mapping"}
    , Entry{kind = WebSourceMaps, identifier = "main.dart.js", path = "/s/map"}
    ]

frame :: T.Text -> T.Text -> T.Text -> Word32 -> Word32 -> Frame
frame moduleName function file line column = Frame{moduleName, function, file, line, column, inApp = True, instructionAddress = Nothing, image = Nothing}

imaged :: T.Text -> T.Text -> Word64 -> Word64 -> Frame
imaged name identifier base address =
  Frame{moduleName = "", function = "", file = "", line = 0, column = 0, inApp = True, instructionAddress = Just address, image = Just Image{name, identifier, loadAddress = base}}

lookups :: Property
lookups = property do
  lookupOf Android symbols 0 (imaged "_kDartIsolateSnapshotInstructions" "abcdef" 0x7000 0x6993b) === DartLookup "/s/dart" 0x6993a
  lookupOf Android symbols 0 (imaged "libapp.so" "0011AA" 0x1000 0x1404) === NativeLookup "/s/ndk" 0x404
  lookupOf Ios symbols 1 (imaged "Runner" "4c4c44575555" 0x1000 0x1404) === NativeLookup "/s/dsym" 0x403
  lookupOf Android symbols 1 (imaged "libapp.so" "0011aa" 0x2000 0x1404) === Unresolvable
  lookupOf Android symbols 0 (imaged "libother.so" "ffff" 0x1000 0x1404) === Unresolvable
  lookupOf Android symbols 2 (frame "a.a" "a" "" 3 0) === JvmLookup "/s/mapping" JvmFrame{className = "a.a", method = "a", file = "", line = 3}
  lookupOf Ios symbols 2 (frame "a.a" "a" "" 3 0) === Unresolvable
  lookupOf Web symbols 0 (frame "" "" "https://shop.example.org/main.dart.js" 2 40) === SourceLookup "/s/map" 2 40
  lookupOf Web symbols 0 (frame "" "" "https://shop.example.org/main.dart.js" 0 0) === Unresolvable
  lookupOf Web symbols 0 (frame "" "" "https://shop.example.org/other.js" 2 0) === Unresolvable

resolved :: Property
resolved = property do
  let dart = imaged "_kDartIsolateSnapshotInstructions" "abcdef" 0 10
      place file = Located{moduleName = "", function = "explode", file, line = 3, column = 0}
      unnamed file = Located{moduleName = "", function = "", file, line = 3, column = 0}
  resolve (DartLookup "/s/dart" 9) dart [] === [dart]
  fmap (\found -> (found.moduleName, found.function, found.inApp, found.instructionAddress)) (resolve (DartLookup "/s/dart" 9) dart [place "package:shop/cart.dart", place "dart:core/errors.dart"])
    === [("shop", "explode", True, Just 10), ("dart:core/errors.dart", "explode", False, Just 10)]
  fmap (.moduleName) (resolve (NativeLookup "/s/ndk" 9) (imaged "libapp.so" "0011aa" 0 10) [place "crash.c"]) === ["libapp.so"]
  fmap (.function) (resolve (SourceLookup "/s/map" 1 1) (frame "" "Object.h" "" 1 1) [unnamed "main.dart"]) === ["Object.h"]
  fmap (.function) (resolve (SourceLookup "/s/map" 1 1) (frame "" "Object.h" "" 1 1) [place "main.dart"]) === ["explode"]

inherited :: Property
inherited = property do
  state <- forAll (Gen.element enumerate)
  count <- forAll (Gen.int (Range.linear 1 5))
  inheritedState (replicate count state) === state
  inheritedState [Resolved, Ignored] === Open
  inheritedState [Resolved, Open, Resolved] === Open
  inheritedState [] === Open

retentions :: Property
retentions = property do
  longestRetention [Just 30, Just 400] === Just 400
  longestRetention [Just 30, Nothing] === Nothing
  longestRetention [] === Just 0

expiry :: Property
expiry = property do
  days <- forAll (Gen.int (Range.linear 1 400))
  elapsed <- forAll (Gen.int (Range.linear 0 800))
  reported <- forAll Gen.bool
  let uploadedAt = UTCTime (fromGregorian 2026 1 1) 0
      now = addUTCTime (fromIntegral elapsed * 86400 + 1) uploadedAt
  expired (Just days) now SymbolBuild{uploadedAt, reported, hasReports = True} === False
  expired (Just days) now SymbolBuild{uploadedAt, reported = True, hasReports = False} === True
  expired Nothing now SymbolBuild{uploadedAt, reported = False, hasReports = False} === False
  expired (Just days) now SymbolBuild{uploadedAt, reported = False, hasReports = False} === (elapsed >= days)
