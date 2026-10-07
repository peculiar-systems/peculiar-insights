module Peculiar.Insights.Core.Symbols
  ( SymbolKind (..)
  , kindName
  , kindFromName
  , Format (..)
  , formatOf
  , Entry (..)
  , Available (..)
  , available
  , normalizeIdentifier
  , scriptName
  , JvmFrame (..)
  , Lookup (..)
  , lookupOf
  , Located (..)
  , resolve
  , dartModule
  , inheritedState
  , longestRetention
  , SymbolBuild (..)
  , expired
  ) where

import Data.Char (toLower)
import Data.Map.Strict qualified as Map
import Data.Maybe (fromMaybe, listToMaybe)
import Data.Text qualified as T
import Data.Time (UTCTime, addUTCTime)
import Data.Word (Word32, Word64)
import GHC.Generics (Generic)
import Optics.Core ((&), (.~))
import Peculiar.Insights.Core.Enum (enumerate)
import Peculiar.Insights.Core.Issue (IssueState (..))
import Peculiar.Insights.Core.Item (Frame (..), Image (..), Platform (..))

data SymbolKind = DartSymbols | WebSourceMaps | R8Mapping | NdkSymbols | Dsyms
  deriving stock (Eq, Ord, Show, Enum, Bounded)

kindName :: SymbolKind -> T.Text
kindName = \case
  DartSymbols -> "dart_symbols"
  WebSourceMaps -> "web_source_maps"
  R8Mapping -> "r8_mapping"
  NdkSymbols -> "ndk_symbols"
  Dsyms -> "dsyms"

kindFromName :: T.Text -> Maybe SymbolKind
kindFromName name = lookup name [(kindName kind, kind) | kind <- enumerate]

data Format = NativeObjects | Mapping | SourceMap
  deriving stock (Eq, Show)

formatOf :: SymbolKind -> Format
formatOf = \case
  DartSymbols -> NativeObjects
  NdkSymbols -> NativeObjects
  Dsyms -> NativeObjects
  R8Mapping -> Mapping
  WebSourceMaps -> SourceMap

data Entry = Entry
  { kind :: SymbolKind
  , identifier :: T.Text
  , path :: FilePath
  }
  deriving stock (Eq, Show)

data Available = Available
  { objects :: Map.Map T.Text FilePath
  , mapping :: Maybe FilePath
  , sourceMaps :: Map.Map T.Text FilePath
  }
  deriving stock (Eq, Show)

available :: [Entry] -> Available
available entries =
  Available
    { objects = Map.fromList [(normalizeIdentifier entry.identifier, entry.path) | entry <- entries, formatOf entry.kind == NativeObjects]
    , mapping = listToMaybe [entry.path | entry <- entries, entry.kind == R8Mapping]
    , sourceMaps = Map.fromList [(scriptName entry.identifier, entry.path) | entry <- entries, entry.kind == WebSourceMaps]
    }

normalizeIdentifier :: T.Text -> T.Text
normalizeIdentifier = T.map toLower . T.filter (/= '-')

scriptName :: T.Text -> T.Text
scriptName = lastSegment . T.takeWhile (\c -> c /= '?' && c /= '#')
 where
  lastSegment path = fromMaybe path (listToMaybe (reverse (filter (not . T.null) (T.splitOn "/" path))))

data JvmFrame = JvmFrame
  { className :: T.Text
  , method :: T.Text
  , file :: T.Text
  , line :: Word32
  }
  deriving stock (Eq, Show)

data Lookup
  = DartLookup FilePath Word64
  | NativeLookup FilePath Word64
  | JvmLookup FilePath JvmFrame
  | SourceLookup FilePath Word32 Word32
  | Unresolvable
  deriving stock (Eq, Show)

lookupOf :: Platform -> Available -> Int -> Frame -> Lookup
lookupOf platform symbols position frame = case (frame.instructionAddress, frame.image) of
  (Just address, Just image) -> case Map.lookup (normalizeIdentifier image.identifier) symbols.objects of
    Nothing -> Unresolvable
    Just object
      | "_kDart" `T.isPrefixOf` image.name -> DartLookup object (callSite address)
      | address < image.loadAddress -> Unresolvable
      | position == 0 -> NativeLookup object (address - image.loadAddress)
      | otherwise -> NativeLookup object (callSite (address - image.loadAddress))
  (Nothing, Nothing)
    | platform == Android
    , not (T.null frame.moduleName)
    , not (T.null frame.function)
    , Just path <- symbols.mapping ->
        JvmLookup path JvmFrame{className = frame.moduleName, method = frame.function, file = frame.file, line = frame.line}
    | platform == Web
    , frame.line > 0
    , Just path <- Map.lookup (scriptName frame.file) symbols.sourceMaps ->
        SourceLookup path frame.line frame.column
  _ -> Unresolvable
 where
  callSite address = if address > 0 then address - 1 else address

data Located = Located
  { moduleName :: T.Text
  , function :: T.Text
  , file :: T.Text
  , line :: Word32
  , column :: Word32
  }
  deriving stock (Eq, Show, Generic)

resolve :: Lookup -> Frame -> [Located] -> [Frame]
resolve how frame = \case
  [] -> [frame]
  located -> fmap (rebuilt how) located
 where
  rebuilt = \case
    DartLookup _ _ -> dartFrame
    SourceLookup{} -> \place -> dartFrame (place & #function .~ (if T.null place.function then frame.function else place.function))
    NativeLookup _ _ -> \place -> replaced (place & #moduleName .~ maybe "" (.name) frame.image)
    JvmLookup _ _ -> replaced
    Unresolvable -> const frame
  dartFrame place = replaced (place & #moduleName .~ dartModule place.file) & #inApp .~ (frame.inApp && not (sdkSource place.file))
  replaced place =
    frame
      & #moduleName
      .~ place.moduleName
      & #function
      .~ place.function
      & #file
      .~ place.file
      & #line
      .~ place.line
      & #column
      .~ place.column
  sdkSource path = any (`T.isPrefixOf` path) ["dart:", "org-dartlang-sdk:"]

dartModule :: T.Text -> T.Text
dartModule path
  | Just rest <- T.stripPrefix "package:" path = T.takeWhile (/= '/') rest
  | Just rest <- T.stripPrefix "dart:" path = "dart:" <> rest
  | otherwise = case filter (not . T.null) (T.splitOn "/" (withoutScheme path)) of
      first : _ -> first
      [] -> path
 where
  withoutScheme text = case T.breakOn "://" text of
    (_, rest) | not (T.null rest) -> T.drop 3 rest
    _ -> text

inheritedState :: [IssueState] -> IssueState
inheritedState = \case
  first : rest | all (== first) rest -> first
  _ -> Open

longestRetention :: [Maybe Int] -> Maybe Int
longestRetention days = maximum' <$> sequence days
 where
  maximum' = foldr max 0

data SymbolBuild = SymbolBuild
  { uploadedAt :: UTCTime
  , reported :: Bool
  , hasReports :: Bool
  }
  deriving stock (Eq, Show)

expired :: Maybe Int -> UTCTime -> SymbolBuild -> Bool
expired longest now build
  | build.hasReports = False
  | build.reported = True
  | otherwise = any (\days -> addUTCTime (fromIntegral days * 86400) build.uploadedAt < now) longest
