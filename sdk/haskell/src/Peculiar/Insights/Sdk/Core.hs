module Peculiar.Insights.Sdk.Core
  ( Core (..)
  , Sink (..)
  , withCore
  , coreSink
  , flushCore
  , purgeCore
  ) where

import Control.Concurrent.Async (withAsync)
import Control.Concurrent.STM
import Control.Exception (assert, finally, try)
import Control.Monad (unless, void, when)
import Data.Foldable (for_)
import Data.IORef (IORef, newIORef, readIORef)
import Data.List (partition)
import Data.Maybe (isNothing, mapMaybe)
import Data.ProtoLens (defMessage)
import Data.ProtoLens.Labels ()
import Data.Text qualified as T
import Data.Time (UTCTime, getCurrentTime, getCurrentTimeZone, timeZoneName)
import Data.UUID qualified as UUID
import Data.UUID.V4 (nextRandom)
import GHC.IORef (atomicModifyIORef'_)
import Lens.Family2 ((&), (.~), (^.))
import Peculiar.Insights.Sdk.Batch (Batch (..), Pending (..), Retry (..), batches, classify, pause)
import Peculiar.Insights.Sdk.Client (IngestClient (..), withRemote)
import Peculiar.Insights.Sdk.Config (Config (..), Diagnostic (..), Drop (..), DropCause (..), Failure (..), Rejection (..))
import Peculiar.Insights.Sdk.Encode (described, encodeConsent, encodeContext, encodeItem, timestamp)
import Peculiar.Insights.Sdk.Purge (Purge (..), Reason (..), reasonFor)
import Peculiar.Insights.Sdk.Spool (Queued (..), Spool (..), noSpool, openSpool)
import Peculiar.Insights.Sdk.Types
import Peculiar.Rpc qualified as Rpc
import Proto.Peculiar.Insights.V1.Common qualified as P
import Proto.Peculiar.Insights.V1.Ingest (Outcome (..))
import System.Environment (lookupEnv)
import System.Info (arch, os)

sdkVersion :: T.Text
sdkVersion = "0.3.0"

data Sink = Sink
  { emit :: Consent -> Item -> IO ()
  , note :: LogLine -> IO ()
  , recent :: IO [LogLine]
  , now :: IO UTCTime
  , diagnose :: Diagnostic -> IO ()
  }

data Core = Core
  { config :: Config
  , remote :: IngestClient
  , queue :: TBQueue Queued
  , flushed :: TVar Int
  , requested :: TVar Int
  , undelivered :: TVar Int
  , purges :: TVar [Purge]
  , logs :: IORef [LogLine]
  , context :: P.Context
  , spool :: Spool
  }

withCore :: Config -> (Core -> IO a) -> IO a
withCore config use =
  withRemote config.endpoint config.key config.callTimeoutSeconds \remote -> do
    (spool, replayed) <- maybe (pure (noSpool, [])) (openSpool (config.onDiagnostic . SpoolFailed)) config.spool
    queue <- newTBQueueIO (fromIntegral (max 1 config.queueCapacity))
    flushed <- newTVarIO 0
    requested <- newTVarIO 0
    undelivered <- newTVarIO (length replayed)
    purges <- newTVarIO []
    logs <- newIORef []
    context <- encodeContext sdkVersion <$> describeHost config
    let core = Core{config, remote, queue, flushed, requested, undelivered, purges, logs, context, spool}
    withAsync (sender core (grouped core replayed)) \_ -> use core `finally` closing core

closing :: Core -> IO ()
closing core = do
  flushCore core
  left <- readTVarIO core.undelivered
  case core.config.spool of
    Nothing -> when (left > 0) (core.config.onDiagnostic (Dropped Drop{count = left, cause = NotDelivered}))
    Just _ -> core.spool.close

describeHost :: Config -> IO Context
describeHost config = do
  locale <- maybe "" T.pack <$> lookupEnv "LANG"
  zone <- T.pack . timeZoneName <$> getCurrentTimeZone
  pure
    Context
      { appVersion = config.appVersion
      , appBuild = config.appBuild
      , platform = Server
      , osName = T.pack os
      , osVersion = ""
      , hostModel = T.pack arch
      , locale
      , timezone = zone
      }

coreSink :: Core -> Sink
coreSink core =
  Sink
    { emit = enqueue core
    , note = \line -> void (atomicModifyIORef'_ core.logs (take core.config.logLimit . (line :)))
    , recent = reverse <$> readIORef core.logs
    , now = getCurrentTime
    , diagnose = core.config.onDiagnostic
    }

enqueue :: Core -> Consent -> Item -> IO ()
enqueue core consent item
  | not (permits consent purpose) = assert False (core.config.onDiagnostic (Dropped Drop{count = 1, cause = NotConsented purpose}))
  | otherwise = do
      at <- getCurrentTime
      identifier <- UUID.toText <$> nextRandom
      let queued = Queued{identifier, consent, item = encodeItem sdkVersion core.context identifier at item}
      core.spool.put queued
      accepted <- atomically do
        full <- isFullTBQueue core.queue
        unless full (writeTBQueue core.queue queued)
        pure (not full)
      unless accepted do
        core.spool.acknowledge [identifier]
        core.config.onDiagnostic (Dropped Drop{count = 1, cause = QueueFull})
 where
  purpose = itemPurpose item

flushCore :: Core -> IO ()
flushCore core = do
  target <- atomically do
    modifyTVar' core.requested (+ 1)
    readTVar core.requested
  atomically do
    done <- readTVar core.flushed
    unless (done >= target) retry

purgeCore :: Core -> Purge -> IO ()
purgeCore core purge = do
  waiting <- atomically do
    modifyTVar' core.purges (purge :)
    waiting <- flushTBQueue core.queue
    let (_, kept) = sifted core [purge] waiting
    for_ kept (writeTBQueue core.queue)
    pure waiting
  discard core (fst (sifted core [purge] waiting))

sifted :: Core -> [Purge] -> [Queued] -> ([(Purge, Queued)], [Queued])
sifted core purges waiting = (mapMaybe (\entry -> (,entry) <$> cause entry) waiting, filter (isNothing . cause) waiting)
 where
  cause entry = described entry.item >>= reasonFor (DeviceId core.config.service) purges

discard :: Core -> [(Purge, Queued)] -> IO ()
discard core dropped = unless (null dropped) do
  core.spool.acknowledge (fmap ((.identifier) . snd) dropped)
  let (withdrawn, erased) = partition ((== ConsentWithdrawn) . (.reason) . fst) dropped
  unless (null withdrawn) (core.config.onDiagnostic (Dropped Drop{count = length withdrawn, cause = AfterWithdrawal}))
  unless (null erased) (core.config.onDiagnostic (Dropped Drop{count = length erased, cause = AfterErasure}))

grouped :: Core -> [Queued] -> [Batch Queued]
grouped core queued = batches core.config.batchSize [Pending{consent = entry.consent, payload = entry} | entry <- queued]

sender :: Core -> [Batch Queued] -> IO ()
sender core = go 0
 where
  go failures carried = do
    wanted <- readTVarIO core.requested
    (drained, purges) <- atomically ((,) <$> flushTBQueue core.queue <*> readTVar core.purges)
    (remaining, wait) <- deliver core failures (carried <> grouped core drained)
    kept <- bounded core remaining
    atomically do
      writeTVar core.undelivered (sum (fmap (length . (.payloads)) kept))
      modifyTVar' core.flushed (max wanted)
      when (null kept) (modifyTVar' core.purges (filter (`notElem` purges)))
    resting core wanted (if null kept then core.config.flushIntervalMicros else wait)
    go (if null kept then 0 else failures + 1) kept

resting :: Core -> Int -> Int -> IO ()
resting core served micros = do
  elapsed <- registerDelay (max 0 micros)
  atomically do
    due <- readTVar elapsed
    asked <- readTVar core.requested
    unless (due || asked > served) retry

bounded :: Core -> [Batch Queued] -> IO [Batch Queued]
bounded core carried = do
  let (kept, shed) = keeping (max 1 core.config.queueCapacity) (reverse carried)
  unless (null shed) do
    core.spool.acknowledge [entry.identifier | batch <- shed, entry <- batch.payloads]
    core.config.onDiagnostic (Dropped Drop{count = sum (fmap (length . (.payloads)) shed), cause = NotDelivered})
  pure (reverse kept)
 where
  keeping _ [] = ([], [])
  keeping room (batch : older)
    | length batch.payloads <= room = let (kept, shed) = keeping (room - length batch.payloads) older in (batch : kept, shed)
    | otherwise = ([], batch : older)

deliver :: Core -> Int -> [Batch Queued] -> IO ([Batch Queued], Int)
deliver core failures = \case
  [] -> pure ([], core.config.flushIntervalMicros)
  asked : rest -> do
    purges <- readTVarIO core.purges
    let (dropped, staying) = sifted core purges asked.payloads
        batch = asked{payloads = staying}
    discard core dropped
    if null staying then deliver core failures rest else sending batch rest
 where
  diagnose = core.config.onDiagnostic
  sending batch rest = do
    at <- getCurrentTime
    let request = defMessage & #sentAt .~ timestamp at & #consent .~ encodeConsent batch.consent & #items .~ fmap (.item) batch.payloads
        settle = core.spool.acknowledge (fmap (.identifier) batch.payloads)
    try @Rpc.RpcError (core.remote.publish request) >>= \case
      Right response -> do
        mapM_
          diagnose
          [ Rejected Rejection{item = o ^. #id, outcome = T.pack (show (o ^. #outcome)), reason = o ^. #reason}
          | o <- response ^. #outcomes
          , o ^. #outcome `notElem` [OUTCOME_ACCEPTED, OUTCOME_DUPLICATE]
          ]
        settle
        deliver core failures rest
      Left failure -> case classify failure.status.code of
        RetryLater -> do
          diagnose (TransportFailed Failure{code = failure.status.code, message = failure.status.message, willRetry = True})
          pure (batch : rest, pause (Rpc.lookupHeader "x-peculiar-retry-after-ms" failure.metadata) failures)
        GiveUp -> do
          diagnose (TransportFailed Failure{code = failure.status.code, message = failure.status.message, willRetry = False})
          diagnose (Dropped Drop{count = length batch.payloads, cause = NotDelivered})
          settle
          deliver core failures rest
