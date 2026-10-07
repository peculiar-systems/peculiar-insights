{-# LANGUAGE TemplateHaskell #-}

module Delivery
  ( tests
  ) where

import Control.Concurrent.Async (withAsync)
import Control.Concurrent.MVar (newEmptyMVar, putMVar, takeMVar)
import Control.Concurrent.STM
import Control.Exception (throwIO)
import Control.Monad.IO.Class (liftIO)
import Data.ByteString qualified as BS
import Data.ByteString.Char8 qualified as BC
import Data.Maybe (isNothing)
import Data.ProtoLens (defMessage)
import Data.ProtoLens.Labels ()
import Data.Set qualified as Set
import Data.Text qualified as T
import Data.Time (UTCTime (..), addUTCTime, fromGregorian)
import Fixtures (consentGen, everything)
import Hedgehog hiding (check)
import Hedgehog.Gen qualified as Gen
import Hedgehog.Range qualified as Range
import Lens.Family2 ((&), (.~), (^.))
import Peculiar.Insights.Sdk hiding (Property)
import Peculiar.Insights.Sdk.Batch (backoff, pause)
import Peculiar.Insights.Sdk.Encode (Described (..), decodeConsent, encodeConsent)
import Peculiar.Insights.Sdk.Purge (Purge (..), Reason (..), covers)
import Peculiar.Insights.Sdk.Spool (Queued (..), Record (..), encodeQueued, frame, surviving, unframe)
import Peculiar.Rpc qualified as Rpc
import Proto.Peculiar.Insights.V1.Ingest qualified as P
import System.FilePath ((</>))
import System.IO.Temp (withSystemTempDirectory)

Rpc.deriveServer ''P.Ingest

tests :: [(PropertyName, Property)]
tests =
  [ ("a consent snapshot reads back as it was written", consentRoundTrip)
  , ("the delay asked for is honoured, within five minutes", pausing)
  , ("spooled records read back, and a torn tail is left out", framing)
  , ("what was acknowledged does not survive", acknowledging)
  , ("what could not be sent is kept on disk and sent by the next process", withTests 1 durable)
  , ("a rate-limited batch is sent again, once, when the server allows", withTests 1 throttled)
  , ("a withdrawal covers that person's earlier items of that purpose, and nothing else", purging)
  , ("what a person withdrew or asked erased is not sent, and the rest is", withTests 1 withdrawing)
  ]

consentRoundTrip :: Property
consentRoundTrip = property do
  consent <- forAll consentGen
  decodeConsent (encodeConsent consent) === consent

pausing :: Property
pausing = property do
  millis <- forAll (Gen.int (Range.linear 0 1_000_000))
  attempt' <- forAll (Gen.int (Range.linear 0 12))
  pause (Just (BC.pack (show millis))) attempt' === min 300_000_000 (millis * 1000)
  malformed <- forAll (Gen.element ["", "soon", "-1", "1.5", "12ms"])
  pause (Just malformed) attempt' === backoff attempt'
  pause Nothing attempt' === backoff attempt'

queuedGen :: Gen Queued
queuedGen = do
  identifier <- Gen.text (Range.singleton 12) Gen.alphaNum
  consent <- consentGen
  name <- Gen.text (Range.linear 1 12) Gen.alpha
  pure Queued{identifier, consent, item = defMessage & #event .~ (defMessage & #id .~ identifier & #name .~ name)}

framing :: Property
framing = property do
  records <- forAll (Gen.list (Range.linear 0 20) (Gen.choice [Put <$> Gen.bytes (Range.linear 0 64), Ack <$> Gen.text (Range.linear 0 40) Gen.unicode]))
  let written = foldMap frame records
  unframe written === records
  cut <- forAll (Gen.int (Range.linear 0 (BS.length written)))
  let read' = unframe (BS.take cut written)
  read' === take (length read') records

acknowledging :: Property
acknowledging = property do
  queued <- forAll (Gen.list (Range.linear 0 20) queuedGen)
  settled <- forAll (Gen.subsequence (fmap (.identifier) queued))
  let records = fmap (Put . encodeQueued) queued <> fmap Ack settled
  fmap (.identifier) (surviving records) === [entry.identifier | entry <- queued, entry.identifier `notElem` settled]

serving :: (P.PublishRequest -> IO (Either Rpc.RpcError ())) -> (Int -> IO a) -> IO a
serving decide use = do
  bound <- newEmptyMVar
  let server =
        IngestServer
          { publish = \_ request ->
              decide request >>= \case
                Left refusal -> throwIO refusal
                Right () -> pure (defMessage & #outcomes .~ [defMessage & #id .~ item ^. #event . #id & #outcome .~ P.OUTCOME_ACCEPTED | item <- request ^. #items])
          , recordConsent = \_ _ -> pure (defMessage & #outcome .~ P.OUTCOME_ACCEPTED)
          , requestErasure = \_ _ -> pure (defMessage & #outcome .~ P.OUTCOME_ACCEPTED)
          }
      settings = Rpc.defaultSettings{Rpc.port = 0, Rpc.onListening = putMVar bound, Rpc.report = const (pure ())}
  withAsync (Rpc.serveEndpoints settings [Rpc.endpoint server]) \_ -> takeMVar bound >>= use

sent :: P.PublishRequest -> [(T.Text, T.Text, Integer)]
sent request = [(item ^. #event . #id, item ^. #event . #name, toInteger (item ^. #event . #time . #seconds)) | item <- request ^. #items]

durable :: Property
durable = property do
  (refused, accepted, complaints) <- liftIO $ withSystemTempDirectory "spool" \directory -> do
    down <- newTVarIO True
    turnedAway <- newTVarIO ([] :: [(T.Text, T.Text, Integer)])
    taken <- newTVarIO ([] :: [(T.Text, T.Text, Integer)])
    complaints <- newTVarIO ([] :: [Diagnostic])
    let decide request =
          readTVarIO down >>= \case
            True -> Left (Rpc.rpcError Rpc.Unavailable "storage is unavailable, retry later") <$ atomically (modifyTVar' turnedAway (<> sent request))
            False -> Right () <$ atomically (modifyTVar' taken (<> sent request))
    serving decide \port -> do
      let config =
            (defaultConfig Endpoint{host = "127.0.0.1", port, tls = False} "secret-key" "api-node-1" everything)
              { flushIntervalMicros = 10_000
              , spool = Just (directory </> "insights")
              , onDiagnostic = \entry -> atomically (modifyTVar' complaints (<> [entry]))
              }
      withInsights config \insights -> do
        track insights.tracker "order_placed" ["total" =: (42 :: Int)]
        insights.flush
      atomically (writeTVar down False)
      withInsights config \insights -> insights.flush
      withInsights config \insights -> insights.flush
    (,,) <$> readTVarIO turnedAway <*> readTVarIO taken <*> readTVarIO complaints
  assert (not (null refused))
  fmap (\(_, name, _) -> name) accepted === ["order_placed"]
  take 1 refused === accepted
  assert (all (\case Dropped _ -> False; SpoolFailed _ -> False; _ -> True) complaints)

throttled :: Property
throttled = property do
  (attempts, complaints) <- liftIO do
    calls <- newTVarIO ([] :: [[(T.Text, T.Text, Integer)]])
    complaints <- newTVarIO ([] :: [Diagnostic])
    let limited =
          Rpc.RpcError
            { Rpc.status = Rpc.Status{Rpc.code = Rpc.ResourceExhausted, Rpc.message = "the rate limit is exceeded, retry later", Rpc.details = []}
            , Rpc.metadata = Rpc.header "x-peculiar-retry-after-ms" "20"
            }
        decide request = atomically do
          earlier <- readTVar calls
          writeTVar calls (earlier <> [sent request])
          pure (if length earlier < 2 then Left limited else Right ())
    serving decide \port -> do
      let config =
            (defaultConfig Endpoint{host = "127.0.0.1", port, tls = False} "secret-key" "api-node-1" everything)
              { flushIntervalMicros = 10_000
              , onDiagnostic = \entry -> atomically (modifyTVar' complaints (<> [entry]))
              }
      withInsights config \insights -> do
        track insights.tracker "order_placed" []
        atomically (readTVar calls >>= check . (>= 3) . length)
        insights.flush
    (,) <$> readTVarIO calls <*> readTVarIO complaints
  length attempts === 3
  assert (all ((== take 1 attempts) . pure) attempts)
  [willRetry | TransportFailed Failure{code = Rpc.ResourceExhausted, willRetry} <- complaints] === [True, True]
  assert (all (\case Dropped _ -> False; _ -> True) complaints)

purging :: Property
purging = property do
  let moment = UTCTime (fromGregorian 2026 1 1) 3600
      service = DeviceId "api-node-1"
  seconds <- forAll (Gen.int (Range.linear (-600) 600))
  purpose <- forAll Gen.enumBounded
  withdrawn <- forAll Gen.enumBounded
  owner <- forAll (Gen.maybe (Gen.element ["ana", "ben"]))
  held <- forAll (Gen.element ["api-node-1", "anas-phone"])
  asked <- forAll (Gen.element [DeviceId "api-node-1", DeviceId "anas-phone"])
  let item = Described{identifier = "i", purpose, device = held, user = owner, time = addUTCTime (fromIntegral seconds) moment}
      asking whose = Purge{device = asked, user = whose, purposes = [withdrawn], at = moment, reason = ConsentWithdrawn}
      purge = asking (Just (UserId "ana"))
      hers = owner == Just "ana"
      onHerDevice = isNothing owner && asked == DeviceId held && asked /= service
  covers service purge item === (purpose == withdrawn && seconds <= 0 && (hers || onHerDevice))
  let anonymous = asking Nothing
  covers service anonymous item === (purpose == withdrawn && seconds <= 0 && isNothing owner && asked == DeviceId held)

withdrawing :: Property
withdrawing = property do
  (taken, complaints) <- liftIO $ withSystemTempDirectory "spool" \directory -> do
    down <- newTVarIO True
    taken <- newTVarIO ([] :: [(T.Text, T.Text, Integer)])
    complaints <- newTVarIO ([] :: [Diagnostic])
    let decide request =
          readTVarIO down >>= \case
            True -> pure (Left (Rpc.rpcError Rpc.Unavailable "storage is unavailable, retry later"))
            False -> Right () <$ atomically (modifyTVar' taken (<> sent request))
    serving decide \port -> do
      let config =
            (defaultConfig Endpoint{host = "127.0.0.1", port, tls = False} "secret-key" "api-node-1" everything)
              { flushIntervalMicros = 10_000
              , spool = Just (directory </> "insights")
              , onDiagnostic = \entry -> atomically (modifyTVar' complaints (<> [entry]))
              }
          granted = Consent{analytics = Just (Granted "v1"), diagnostics = Just (Granted "v1")}
          person name = Subject{device = DeviceId "api-node-1", user = Just (UserId name), session = SessionId (name <> "-s")}
      withInsights config \insights -> do
        let ana = insights.subject (person "ana") granted
            ben = insights.subject (person "ben") granted
            cyd = insights.subject (person "cyd") granted
        track ana "ana_ordered" []
        track ben "ben_ordered" []
        track cyd "cyd_ordered" []
        track insights.tracker "service_started" []
        insights.flush
        track ana "ana_waiting" []
        _ <- insights.recordConsent (DeviceId "api-node-1") (Just (UserId "ana")) Analytics (Withdrawn "v1")
        _ <- insights.erase (DeviceId "api-node-1") (Just (UserId "cyd"))
        track ben "ben_again" []
        atomically (writeTVar down False)
        insights.flush
      withInsights config \insights -> insights.flush
    (,) <$> readTVarIO taken <*> readTVarIO complaints
  Set.fromList (fmap (\(_, name, _) -> name) taken) === Set.fromList ["ben_ordered", "service_started", "ben_again"]
  length taken === 3
  sum [count | Dropped Drop{count, cause = AfterWithdrawal} <- complaints] === 2
  sum [count | Dropped Drop{count, cause = AfterErasure} <- complaints] === 1
  [cause | Dropped Drop{cause} <- complaints, cause `notElem` [AfterWithdrawal, AfterErasure]] === []
