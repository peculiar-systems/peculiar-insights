module Peculiar.Insights.Server.SymbolStore
  ( Received (..)
  , Indexing (..)
  , Unindexed (..)
  , Destination (..)
  , indexing
  , keep
  , pruneSymbols
  , safeName
  ) where

import Control.Exception (IOException, try)
import Data.Aeson (toJSON)
import Data.Char (isAsciiLower, isAsciiUpper, isDigit)
import Data.Foldable (for_)
import Data.List.NonEmpty (NonEmpty (..))
import Data.List.NonEmpty qualified as NonEmpty
import Data.Maybe (fromMaybe)
import Data.Text qualified as T
import Data.Time (UTCTime)
import Data.Traversable (for)
import Peculiar.Insights.Core.Config (Project (..))
import Peculiar.Insights.Core.Symbols (Entry (..), SymbolBuild (..), SymbolKind (..), expired, formatOf, kindName, longestRetention)
import Peculiar.Insights.Server.Db (Db (..), DbError, KeptBuild (..), StoredKind (..))
import Peculiar.Insights.Server.Env (HasDb (..), HasJournal (..))
import Peculiar.Insights.Server.Journal (Journal (..))
import Peculiar.Insights.Server.Projects (Registered (..))
import Peculiar.Insights.Server.Symbolicator (Indexed (..), Symbolicator (..), SymbolicatorError)
import System.Directory (createDirectoryIfMissing, removePathForcibly, renameDirectory)
import System.FilePath (makeRelative, takeFileName, (</>))

data Received = Received
  { kind :: SymbolKind
  , name :: T.Text
  , path :: FilePath
  }

data Indexing = Indexing
  { kind :: SymbolKind
  , files :: Int
  , entries :: [Entry]
  }

data Unindexed = Unindexed T.Text SymbolicatorError

data Destination = Destination
  { directory :: FilePath
  , project :: T.Text
  , build :: T.Text
  , staging :: FilePath
  }

indexing :: Symbolicator -> FilePath -> SymbolKind -> NonEmpty Received -> IO (Either Unindexed Indexing)
indexing symbolicator staging kind files = do
  let home = staging </> T.unpack (kindName kind)
      cache = home </> "cache"
  createDirectoryIfMissing True cache
  found <- for (NonEmpty.toList files) \file ->
    symbolicator.inspect (formatOf kind) file.path cache >>= \case
      Left failure -> pure (Left (Unindexed file.name failure))
      Right indexed -> pure (Right [Entry{kind, identifier = identifierOf file entry, path = makeRelative home entry.path} | entry <- indexed])
  pure (Indexing kind (NonEmpty.length files) . concat <$> sequenceA found)
 where
  identifierOf file entry
    | kind == WebSourceMaps && T.null entry.identifier = fromMaybe file.name (T.stripSuffix ".map" file.name)
    | otherwise = entry.identifier

keep :: (HasDb env) => env -> Destination -> UTCTime -> [Indexing] -> IO (Either DbError [FilePath])
keep env destination now indexed =
  (getDb env).openSymbolBuild destination.project destination.build now >>= \case
    Left failure -> pure (Left failure)
    Right buildId -> do
      let home = destination.directory </> show buildId
      createDirectoryIfMissing True home
      stored <- for indexed \kept -> do
        let final = home </> (T.unpack (kindName kept.kind) <> "-" <> takeFileName destination.staging)
        renameDirectory (destination.staging </> T.unpack (kindName kept.kind)) final
        pure StoredKind{kind = kept.kind, directory = final, files = kept.files, entries = [Entry{kind = entry.kind, identifier = entry.identifier, path = final </> entry.path} | entry <- kept.entries]}
      (getDb env).replaceSymbols buildId destination.project destination.build stored

pruneSymbols :: (HasDb env, HasJournal env) => env -> UTCTime -> [Registered] -> IO (Either DbError ())
pruneSymbols env now registered =
  (getDb env).symbolBuilds >>= \case
    Left failure -> pure (Left failure)
    Right builds -> do
      let retentionOf project = longestRetention [entry.project.retentionDays | entry <- registered, entry.project.slug == project]
          doomed = [build.id | build <- builds, expired (retentionOf build.project) now (symbolBuildOf build)]
      (getDb env).dropSymbolBuilds doomed >>= \case
        Left failure -> pure (Left failure)
        Right directories -> do
          for_ directories \path ->
            try @IOException (removePathForcibly path) >>= \case
              Left failure -> (getJournal env).write "symbols-undeleted" (toJSON (show failure))
              Right () -> pure ()
          pure (Right ())
 where
  symbolBuildOf build = SymbolBuild{uploadedAt = build.uploadedAt, reported = build.reported, hasReports = build.hasReports}

safeName :: T.Text -> T.Text
safeName name = case T.map safe (T.pack (takeFileName (T.unpack (T.replace "\\" "/" name)))) of
  "" -> "file"
  cleaned -> cleaned
 where
  safe c = if isAsciiLower c || isAsciiUpper c || isDigit c || c `elem` ['.', '_', '-'] then c else '_'
