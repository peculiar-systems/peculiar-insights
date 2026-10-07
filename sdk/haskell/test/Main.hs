{-# LANGUAGE TemplateHaskell #-}

module Main (main) where

import Control.Concurrent.Async (withAsync)
import Control.Concurrent.MVar (newEmptyMVar, putMVar, takeMVar)
import Control.Concurrent.STM
import Control.Exception (ErrorCall (..), throwIO, try)
import Control.Monad (unless)
import Control.Monad.IO.Class (liftIO)
import Data.ByteString qualified as BS
import Data.IORef (modifyIORef', newIORef, readIORef)
import Data.Map.Strict qualified as Map
import Data.ProtoLens (defMessage)
import Data.ProtoLens.Labels ()
import Data.Text qualified as T
import Data.Time (UTCTime (..), addUTCTime, fromGregorian)
import Delivery qualified
import Fixtures (consentGen, device, everything)
import Hedgehog hiding (check, classify)
import Hedgehog.Gen qualified as Gen
import Hedgehog.Range qualified as Range
import Lens.Family2 ((&), (.~), (^.))
import Peculiar.Insights.Sdk hiding (Property)
import Peculiar.Insights.Sdk.Batch
import Peculiar.Insights.Sdk.Testing (Recorded (..), recording, recordingAt)
import Peculiar.Rpc qualified as Rpc
import Proto.Peculiar.Insights.V1.Ingest qualified as P
import System.Exit (exitFailure)
import Prelude hiding (log, span)

Rpc.deriveServer ''P.Ingest

main :: IO ()
main = do
  ok <-
    checkParallel
      ( Group
          "Sdk"
          ( [ ("batches never mix consent snapshots", batchesByConsent)
            , ("batches respect the size limit", batchesBounded)
            , ("only transport failures and rate limits retry", retryClassification)
            , ("scope folds into events and the event wins", scoping)
            , ("a span records its duration", spans)
            , ("attempt records the failure with frames and rethrows", attempting)
            , ("profiles need an identified user", profilesNeedUser)
            , ("an assumed policy records its grants and tracks under them", withTests 1 assumed)
            ]
              <> Delivery.tests
          )
      )
  unless ok exitFailure

batchesByConsent :: Property
batchesByConsent = property do
  pending <- forAll (Gen.list (Range.linear 0 40) (Pending <$> consentGen <*> Gen.int (Range.linear 0 100)))
  size <- forAll (Gen.int (Range.linear 1 10))
  let produced = batches size pending
  length (concatMap (.payloads) produced) === length pending
  assert (all (\batch -> all (\payload -> Pending batch.consent payload `elem` pending) batch.payloads) produced)

batchesBounded :: Property
batchesBounded = property do
  pending <- forAll (Gen.list (Range.linear 0 40) (Pending <$> consentGen <*> Gen.int (Range.linear 0 100)))
  size <- forAll (Gen.int (Range.linear 1 10))
  assert (all (\batch -> length batch.payloads <= size && not (null batch.payloads)) (batches size pending))

retryClassification :: Property
retryClassification = property do
  code <- forAll Gen.enumBounded
  classify code === (if code `elem` ([Rpc.Unavailable, Rpc.Unknown, Rpc.DeadlineExceeded, Rpc.ResourceExhausted] :: [Rpc.Code]) then RetryLater else GiveUp)

scoping :: Property
scoping = property do
  screen <- forAll (Gen.text (Range.linear 1 10) Gen.alpha)
  total <- forAll (Gen.int (Range.linear 0 1000))
  recorded <- liftIO do
    (insights, items, _) <- recording everything device
    let tracker = with ["screen" =: screen, "total" =: (0 :: Int)] insights.tracker
    track tracker "order_placed" ["total" =: total]
    items
  case recorded of
    [Recorded{item = Track _ name props}] -> do
      name === "order_placed"
      Map.lookup "screen" props === Just (VString screen)
      Map.lookup "total" props === Just (VInt (fromIntegral total))
    other -> annotateShow other *> failure

spans :: Property
spans = property do
  millis <- forAll (Gen.int (Range.linear 0 100_000))
  recorded <- liftIO do
    clock <- newIORef (UTCTime (fromGregorian 2026 1 1) 0)
    (insights, items, _) <- recordingAt (readIORef clock) everything device
    handle <- span insights.tracker "checkout"
    modifyIORef' clock (addUTCTime (fromIntegral millis / 1000))
    handle.end ["items" =: (3 :: Int)]
    items
  case recorded of
    [Recorded{item = Track _ "checkout" props}] -> do
      Map.lookup "duration_ms" props === Just (VInt (fromIntegral millis))
      Map.lookup "items" props === Just (VInt 3)
    other -> annotateShow other *> failure

attempting :: Property
attempting = property do
  message <- forAll (Gen.text (Range.linear 1 20) Gen.alphaNum)
  (outcome, recorded) <- liftIO do
    (insights, items, _) <- recording everything device
    log insights.tracker Info "about to pay"
    outcome <- try @ErrorCall (attempt insights.tracker (throwIO (ErrorCall (show message)) :: IO ()))
    (,) outcome <$> items
  outcome === Left (ErrorCall (show message))
  case recorded of
    [Recorded{item = Crash _ crash}] -> do
      crash.exceptionType === "ErrorCall"
      crash.fatal === False
      assert (not (null crash.frames))
      fmap (.message) crash.logs === ["about to pay"]
    other -> annotateShow other *> failure

profilesNeedUser :: Property
profilesNeedUser = withTests 1 $ property do
  (recorded, diagnostics) <- liftIO do
    (insights, items, diagnostics) <- recording everything Subject{device = DeviceId "d", user = Nothing, session = SessionId "s"}
    (people insights.tracker).set ["plan" =: ("pro" :: T.Text)]
    (,) <$> items <*> diagnostics
  recorded === []
  diagnostics === [Dropped Drop{count = 1, cause = NoUser}]

assumed :: Property
assumed = property do
  seen <- liftIO (newTVarIO [])
  consents <- liftIO (newTVarIO [])
  bound <- liftIO newEmptyMVar
  let server =
        IngestServer
          { publish = capturing seen
          , recordConsent = \_ request -> do
              atomically (modifyTVar' consents ((request ^. #purpose . #policyVersion) :))
              pure (defMessage & #outcome .~ P.OUTCOME_ACCEPTED)
          , requestErasure = \_ _ -> pure (defMessage & #outcome .~ P.OUTCOME_ACCEPTED)
          }
      settings = Rpc.defaultSettings{Rpc.port = 0, Rpc.onListening = putMVar bound, Rpc.report = const (pure ())}
  (requests, grants) <- liftIO $ withAsync (Rpc.serveEndpoints settings [Rpc.endpoint server]) \_ -> do
    port <- takeMVar bound
    let config =
          (defaultConfig Endpoint{host = "127.0.0.1", port, tls = False} "secret-key" "api-node-1" everything)
            { flushIntervalMicros = 10_000
            , appVersion = "1"
            }
    withInsights config \insights -> do
      track insights.tracker "service_started" ["runtime" =: ("ghc" :: T.Text)]
      track (insights.subject device noConsent) "hidden" []
      insights.flush
    (,) <$> readTVarIO seen <*> readTVarIO consents
  grants === ["test", "test"]
  case requests of
    [(headers, request)] -> do
      headers === ["Bearer secret-key"]
      fmap (\item -> item ^. #event . #name) (request ^. #items) === ["service_started"]
      length (request ^. #consent . #purposes) === 2
    other -> annotateShow (length other) *> failure

capturing :: TVar [([BS.ByteString], P.PublishRequest)] -> Rpc.Context -> P.PublishRequest -> IO P.PublishResponse
capturing seen context request = do
  let auth = Rpc.lookupHeaders "authorization" context.metadata
  atomically (modifyTVar' seen ((auth, request) :))
  pure (defMessage & #outcomes .~ [defMessage & #id .~ item ^. #event . #id & #outcome .~ P.OUTCOME_ACCEPTED | item <- request ^. #items])
