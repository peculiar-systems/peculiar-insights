module Peculiar.Insights.Server.Symbolicate
  ( symbolicate
  , symbolicateItems
  , resymbolicate
  ) where

import Data.Aeson (toJSON)
import Data.List.Extra (zipFrom, zipWithFrom)
import Data.Map.Strict qualified as Map
import Data.Maybe (catMaybes, fromMaybe)
import Data.Set qualified as Set
import Data.Text qualified as T
import Data.Traversable (for)
import Data.Word (Word64)
import Peculiar.Insights.Core.Config (Project (..))
import Peculiar.Insights.Core.Fingerprint (Fingerprint (..), fingerprint, title)
import Peculiar.Insights.Core.Item (Context (..), CrashReport (..), Frame, Item (..), ItemId, Platform)
import Peculiar.Insights.Core.Symbols (Available, Located, Lookup (..), available, lookupOf, resolve)
import Peculiar.Insights.Server.Db (BuildCrash (..), Db (..), DbError, Regrouped (..), describeDbError)
import Peculiar.Insights.Server.Env (HasDb (..), HasJournal (..), HasSymbolicator (..))
import Peculiar.Insights.Server.Journal (Journal (..))
import Peculiar.Insights.Server.Projects (Registered (..))
import Peculiar.Insights.Server.Symbolicator (Symbolicator (..), SymbolicatorError, describeSymbolicatorError)

symbolicate :: Symbolicator -> Platform -> Available -> [Frame] -> IO (Either SymbolicatorError [Frame])
symbolicate symbolicator platform symbols frames = do
  let lookups = zipWithFrom (lookupOf platform symbols) 0 frames
      numbered = zipFrom (0 :: Int) lookups
  answered <-
    sequence
      [ answering [(path, (position, address)) | (position, how) <- numbered, Just (path, address) <- [nativeOf how]] symbolicator.lookupNative
      , answering [(path, (position, frame)) | (position, JvmLookup path frame) <- numbered] symbolicator.retrace
      , answering [(path, (position, (line, column))) | (position, SourceLookup path line column) <- numbered] symbolicator.mapSource
      ]
  pure do
    found <- Map.unions <$> sequenceA answered
    Right (concat (zipWith (\(position, how) frame -> resolve how frame (Map.findWithDefault [] position found)) numbered frames))

nativeOf :: Lookup -> Maybe (FilePath, Word64)
nativeOf = \case
  DartLookup path address -> Just (path, address)
  NativeLookup path address -> Just (path, address)
  _ -> Nothing

answering :: [(FilePath, (Int, a))] -> (FilePath -> [a] -> IO (Either SymbolicatorError [[Located]])) -> IO (Either SymbolicatorError (Map.Map Int [Located]))
answering requests call = do
  answered <- for (Map.toList (Map.fromListWith (flip (<>)) [(path, [member]) | (path, member) <- requests])) \(path, members) ->
    fmap (Map.fromList . zip (fmap fst members)) <$> call path (fmap snd members)
  pure (Map.unions <$> sequenceA answered)

symbolicateItems :: (HasDb env, HasJournal env, HasSymbolicator env) => env -> Registered -> [Item] -> IO (Map.Map ItemId [Frame])
symbolicateItems env registered items = do
  let project = registered.project.slug
      crashes = [crash | ItemCrashReport crash <- items]
      builds = Set.toList (Set.fromList (fmap (.context.appBuild) crashes))
  known <- Map.fromList <$> for builds \build -> (build,) <$> symbolsOf env project build
  found <- for crashes \crash -> case Map.lookup crash.context.appBuild known of
    Just symbols | symbols /= available [] -> fmap (crash.id,) <$> framesOf env crash.context.platform symbols crash.frames
    _ -> pure Nothing
  pure (Map.fromList (catMaybes found))

resymbolicate :: (HasDb env, HasJournal env, HasSymbolicator env) => env -> T.Text -> T.Text -> IO (Either DbError ())
resymbolicate env project build =
  (getDb env).buildCrashes project build >>= \case
    Left failure -> pure (Left failure)
    Right crashes -> do
      symbols <- symbolsOf env project build
      regrouped <- for crashes \crash -> do
        frames <- fromMaybe crash.rawFrames <$> framesOf env crash.platform symbols crash.rawFrames
        let Fingerprint printed = fingerprint crash.exceptionType crash.message frames
        pure Regrouped{crash, frames, fingerprint = printed, title = title crash.exceptionType crash.message frames}
      (getDb env).regroup regrouped

symbolsOf :: (HasDb env, HasJournal env) => env -> T.Text -> T.Text -> IO Available
symbolsOf env project build =
  (getDb env).symbolEntries project build >>= \case
    Left failure -> available [] <$ (getJournal env).write "symbols-unreadable" (toJSON (describeDbError failure))
    Right entries -> pure (available entries)

framesOf :: (HasJournal env, HasSymbolicator env) => env -> Platform -> Available -> [Frame] -> IO (Maybe [Frame])
framesOf env platform symbols frames =
  symbolicate (getSymbolicator env) platform symbols frames >>= \case
    Left failure -> Nothing <$ (getJournal env).write "symbolication-failed" (toJSON (describeSymbolicatorError failure))
    Right resolved -> pure (Just resolved)
