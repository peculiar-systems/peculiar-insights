{-# LANGUAGE TemplateHaskell #-}

module Test.Peculiar.Insights.Server.Regrouping
  ( tests
  ) where

import Control.Monad (void)
import Control.Monad.IO.Class (liftIO)
import Data.ByteString qualified as BS
import Data.FileEmbed (embedFile)
import Data.Int (Int64)
import Data.String (fromString)
import Data.Text qualified as T
import Data.Text.Encoding qualified as TE
import Data.Time (addUTCTime, getCurrentTime, nominalDay)
import Database.PostgreSQL.Simple (query_)
import Hedgehog
import Peculiar.Insights.Core.Config (Project (..))
import Peculiar.Insights.Core.Item (Frame (..))
import Peculiar.Insights.Server.Db (Db (..), Disposition (..), Retention (..), Target (..))
import Peculiar.Insights.Server.Env (HasDb (..), HasJournal (..))
import Peculiar.Insights.Server.Journal (Journal, silentJournal)
import Peculiar.Insights.Server.Projects (Registered (..))
import Peculiar.Insights.Server.SymbolStore (pruneSymbols)
import Proto.Peculiar.Insights.V1.Common (Platform (..))
import System.Directory (doesDirectoryExist)
import Test.Peculiar.Insights.Server.Db (register)
import Test.Peculiar.Insights.Server.SymbolFixtures
import Test.Peculiar.Insights.Server.Traces

data Pruning = Pruning
  { db :: Db
  , journal :: Journal
  }

instance HasDb Pruning where
  getDb env = env.db

instance HasJournal Pruning where
  getJournal env = env.journal

alertRules :: BS.ByteString
alertRules = $(embedFile "../../grafana/alerting/rules.yaml")

tests :: Suite -> Group
tests suite =
  Group
    "Regrouping"
    [ ("a report stored before its symbols is symbolicated and regrouped when they arrive, alerting only on arrival", withTests 1 (lateSymbols suite))
    , ("regrouping carries a shared state, opens on differing states and keeps an existing issue's own", withTests 1 (regroupedStates suite))
    , ("symbols are deleted once no report of their build is retained, or after the longest retention without one", withTests 1 (retained suite))
    ]

newIssues :: Suite -> IO [Int64]
newIssues suite = withConnection suite \connection -> do
  let sql = alertQuery "peculiar-insights-new-issue"
  rows <- query_ connection (fromString (T.unpack sql))
  pure [count | (named :: T.Text, count) <- rows, named == "shop/test"]

alertQuery :: T.Text -> T.Text
alertQuery uid =
  let rules = TE.decodeUtf8 alertRules
      (_, from) = T.breakOn ("uid: " <> uid) rules
      (_, sql) = T.breakOn "rawSql: >-" from
      body = takeWhile (\line -> T.isPrefixOf "                " line || T.null (T.strip line)) (afterFirst (T.lines sql))
   in T.unwords (fmap T.strip (takeWhile (not . T.null . T.strip) body))
 where
  afterFirst = \case
    _ : rest -> rest
    [] -> []

lateSymbols :: Suite -> Property
lateSymbols suite = property do
  frames <- liftIO (dartTrace suite)
  (before, rawIssue, alertedOnArrival, after, movedIssue, alertedAfter, rawGone) <- liftIO $ serving suite roomy \port -> do
    item <- crashOf (crashId 5) "late-1" PLATFORM_IOS "LateError" frames
    void (publishing port [item])
    before <- framesOf suite 5
    rawIssue <- issueOf suite 5
    alertedOnArrival <- newIssues suite
    void (uploading suite port shopKey "late-1" [("dart-symbols", "dart/app.symbols")])
    after <- framesOf suite 5
    movedIssue <- issueOf suite 5
    alertedAfter <- newIssues suite
    rawGone <- issueExists suite rawIssue
    pure (before, rawIssue, alertedOnArrival, after, movedIssue, alertedAfter, rawGone)
  before === frames
  take 1 (fmap located after) === [("explode", "main.dart", 3)]
  movedIssue /== rawIssue
  assert (sum alertedOnArrival >= 1)
  sum alertedAfter === sum alertedOnArrival - 1
  rawGone === False
  titled <- liftIO (issueTitle suite movedIssue)
  titled === Just ("LateError in " <> foldMap (.moduleName) (take 1 after) <> ".explode")

unnamed :: [Frame] -> [Frame]
unnamed = fmap (\frame -> frame{function = ""})

regroupedStates :: Suite -> Property
regroupedStates suite = property do
  frames <- liftIO (dartTrace suite)
  let target = Target{slug = "shop", environment = "test"}
      triage issue disposition = void (suite.db.triage target disposition issue)
      raw n build = crashOf (crashId n) build PLATFORM_ANDROID
  outcome <- liftIO $ serving suite roomy \port -> do
    shared <- traverse (\(n, variant) -> raw n "states-shared" "SharedError" variant) [(10, frames), (11, unnamed frames)]
    differing <- traverse (\(n, variant) -> raw n "states-differing" "DifferingError" variant) [(12, frames), (13, unnamed frames)]
    void (publishing port (shared <> differing))
    sharedIssues <- traverse (issueOf suite) [10, 11]
    differingIssues <- traverse (issueOf suite) [12, 13]
    traverse_' (`triage` Resolve) sharedIssues
    traverse_' (uncurry triage) (zip differingIssues [Resolve, Ignore])
    void (uploading suite port shopKey "states-shared" [("dart-symbols", "dart/app.symbols")])
    void (uploading suite port shopKey "states-differing" [("dart-symbols", "dart/app.symbols")])
    void (uploading suite port shopKey "states-existing-a" [("dart-symbols", "dart/app.symbols")])
    existing <- raw 14 "states-existing-a" "ExistingError" frames
    void (publishing port [existing])
    existingIssue <- issueOf suite 14
    triage existingIssue Ignore
    joining <- raw 15 "states-existing-b" "ExistingError" frames
    void (publishing port [joining])
    joiningIssue <- issueOf suite 15
    triage joiningIssue Resolve
    void (uploading suite port shopKey "states-existing-b" [("dart-symbols", "dart/app.symbols")])
    sharedNow <- traverse (issueOf suite) [10, 11]
    differingNow <- traverse (issueOf suite) [12, 13]
    joinedNow <- issueOf suite 15
    states <- traverse (issueState suite) [headOr 0 sharedNow, headOr 0 differingNow, existingIssue]
    left <- traverse (issueExists suite) (sharedIssues <> differingIssues <> [joiningIssue])
    pure (sharedNow, differingNow, joinedNow, existingIssue, states, left)
  let (sharedNow, differingNow, joinedNow, existingIssue, states, left) = outcome
  length (unique sharedNow) === 1
  length (unique differingNow) === 1
  joinedNow === existingIssue
  states === [Just "resolved", Just "open", Just "ignored"]
  left === replicate 5 False
 where
  traverse_' f = foldr ((*>) . f) (pure ())
  headOr fallback = \case
    first : _ -> first
    [] -> fallback
  unique = foldr (\x seen -> if x `elem` seen then seen else x : seen) []

retained :: Suite -> Property
retained suite = property do
  registered <- liftIO (register suite.db)
  frames <- liftIO (dartTrace suite)
  now <- liftIO getCurrentTime
  let pruning = Pruning{db = suite.db, journal = silentJournal}
      forever' = registered{project = registered.project{retentionDays = Nothing}}
  outcome <- liftIO $ serving suite roomy \port -> do
    void (uploading suite port shopKey "kept-1" [("dart-symbols", "dart/app.symbols")])
    void (uploading suite port shopKey "orphan-1" [("dart-symbols", "dart/app.symbols")])
    item <- crashOf (crashId 20) "kept-1" PLATFORM_ANDROID "KeptError" frames
    void (publishing port [item])
    keptDirectory <- kindDirectory suite "kept-1" "dart_symbols"
    void (pruneSymbols pruning now [registered])
    keptWhileReported <- stored suite "kept-1"
    void (pruneSymbols pruning (addUTCTime (29 * nominalDay) now) [registered])
    orphanEarly <- stored suite "orphan-1"
    void (pruneSymbols pruning (addUTCTime (31 * nominalDay) now) [registered, forever'])
    orphanForever <- stored suite "orphan-1"
    void (pruneSymbols pruning (addUTCTime (31 * nominalDay) now) [registered])
    orphanLate <- stored suite "orphan-1"
    void (suite.db.retain (addUTCTime (60 * nominalDay) now) [Retention{registered, cutoff = addUTCTime nominalDay now}])
    void (pruneSymbols pruning now [registered])
    keptAfterRetention <- stored suite "kept-1"
    keptGone <- not <$> maybe (pure False) doesDirectoryExist keptDirectory
    pure (keptWhileReported, orphanEarly, orphanForever, orphanLate, keptAfterRetention, keptGone)
  let (keptWhileReported, orphanEarly, orphanForever, orphanLate, keptAfterRetention, keptGone) = outcome
  keptWhileReported === ["dart_symbols"]
  orphanEarly === ["dart_symbols"]
  orphanForever === ["dart_symbols"]
  orphanLate === []
  keptAfterRetention === []
  keptGone === True
