module Test.Peculiar.Insights.Server.Api
  ( tests
  ) where

import Control.Exception (try)
import Control.Monad.IO.Class (liftIO)
import Data.ByteString.Char8 qualified as BC
import Data.ByteString.Lazy qualified as LBS
import Data.ProtoLens (defMessage)
import Data.ProtoLens.Labels ()
import Data.Text qualified as T
import Data.Text.Encoding qualified as TE
import Data.UUID.Types qualified as UUID
import Hedgehog
import Lens.Family2 ((^.))
import Network.HTTP.Client qualified as Http
import Network.HTTP.Types (statusCode)
import Network.Wai.Handler.Warp (testWithApplication)
import Peculiar.Insights.Core.Config (PeerLimit (..), Rate (..))
import Peculiar.Insights.Core.Metrics (Series (..))
import Peculiar.Insights.Server.Admission (peerOf)
import Peculiar.Insights.Server.Api (IngestClient (..))
import Peculiar.Insights.Server.Db (Db)
import Peculiar.Insights.Server.Metrics (Metrics (..), exposing, newMetrics)
import Peculiar.Rpc qualified as Rpc
import Proto.Peculiar.Insights.V1.Ingest
import Test.Peculiar.Insights.Server.Harness (granted, natively, remote, request, sampleEvent, withLimited, withServer)

tests :: Db -> Group
tests db =
  Group
    "Api"
    [ ("a call without a key is unauthenticated", withTests 1 (unauthenticated db))
    , ("a consented event is accepted once and then a duplicate", withTests 1 (accepted db))
    , ("an event without consent is refused", withTests 1 (refused db))
    , ("an item with a malformed id is invalid", withTests 1 (malformed db))
    , ("a key past its limit is told when to come back, and the rest is counted", withTests 1 (limited db))
    , ("a peer past its limit is refused whatever its key allows", withTests 1 (crowded db))
    , ("the peer is the forwarded address when one is trusted", withTests 1 forwarded)
    , ("the exposition is served at /metrics and nowhere else", withTests 1 exposed)
    , ("the health service refuses JSON", withTests 1 (healthJson db))
    ]

unauthenticated :: Db -> Property
unauthenticated db = property do
  outcome <- liftIO $ withServer db \port -> do
    api <- remote port Nothing
    body <- request granted []
    try @Rpc.RpcError (api.publish body)
  case outcome of
    Left rejected -> rejected.status.code === Rpc.Unauthenticated
    Right response -> annotateShow response *> failure

accepted :: Db -> Property
accepted db = property do
  (first, second) <- liftIO $ withServer db \port -> do
    api <- remote port (Just "test-key")
    item <- sampleEvent (UUID.toText (UUID.fromWords 9 1 0 1))
    body <- request granted [item]
    (,) <$> api.publish body <*> api.publish body
  fmap (^. #outcome) (first ^. #outcomes) === [OUTCOME_ACCEPTED]
  fmap (^. #outcome) (second ^. #outcomes) === [OUTCOME_DUPLICATE]

refused :: Db -> Property
refused db = property do
  response <- liftIO $ withServer db \port -> do
    api <- remote port (Just "test-key")
    item <- sampleEvent (UUID.toText (UUID.fromWords 9 2 0 1))
    body <- request defMessage [item]
    api.publish body
  fmap (^. #outcome) (response ^. #outcomes) === [OUTCOME_NOT_CONSENTED]

malformed :: Db -> Property
malformed db = property do
  response <- liftIO $ withServer db \port -> do
    api <- remote port (Just "test-key")
    item <- sampleEvent "not-a-uuid"
    body <- request granted [item]
    api.publish body
  fmap (^. #outcome) (response ^. #outcomes) === [OUTCOME_INVALID]
  fmap (^. #id) (response ^. #outcomes) === ["not-a-uuid"]

limited :: Db -> Property
limited db = property do
  (first, second, overWeb, exposition) <- liftIO $ withLimited db (Just Rate{perMinute = 60, burst = 2}) Nothing \port exposition -> do
    one <- sampleEvent (UUID.toText (UUID.fromWords 9 5 0 1))
    two <- sampleEvent (UUID.toText (UUID.fromWords 9 5 0 2))
    three <- sampleEvent (UUID.toText (UUID.fromWords 9 5 0 3))
    (within, beyond) <- natively port "test-key" \api ->
      (,) <$> (request granted [one, two] >>= api.publish) <*> (request granted [three] >>= try @Rpc.RpcError . api.publish)
    web <- remote port (Just "test-key")
    again <- request granted [three] >>= try @Rpc.RpcError . web.publish
    (,,,) within beyond again <$> exposition
  annotateShow (either (\rejected -> Rpc.headers rejected.metadata) (const []) overWeb)
  fmap (^. #outcome) (first ^. #outcomes) === [OUTCOME_ACCEPTED, OUTCOME_ACCEPTED]
  case second of
    Right response -> annotateShow response *> failure
    Left rejected -> do
      rejected.status.code === Rpc.ResourceExhausted
      case Rpc.lookupHeader "x-peculiar-retry-after-ms" rejected.metadata >>= BC.readInt of
        Just (millis, "") -> assert (millis >= 250 && millis <= 300000)
        other -> annotateShow other *> failure
  annotate (T.unpack exposition)
  assert ("insights_items_total{environment=\"test\",outcome=\"accepted\",project=\"shop\"} 2\n" `T.isInfixOf` exposition)
  assert ("insights_rate_limited_total{environment=\"test\",project=\"shop\",scope=\"key\"} 2\n" `T.isInfixOf` exposition)
  assert ("insights_requests_total{code=\"ok\",method=\"Publish\"} 1\n" `T.isInfixOf` exposition)
  assert ("insights_requests_total{code=\"resource_exhausted\",method=\"Publish\"} 2\n" `T.isInfixOf` exposition)
  either (\rejected -> Rpc.lookupHeader "x-peculiar-retry-after-ms" rejected.metadata) (const Nothing) overWeb /== Nothing

crowded :: Db -> Property
crowded db = property do
  let peers = PeerLimit{rate = Rate{perMinute = 60, burst = 1}, forwardedHeader = Nothing}
  (first, second) <- liftIO $ withLimited db (Just Rate{perMinute = 6000, burst = 6000}) (Just peers) \port _ -> do
    api <- remote port (Just "test-key")
    one <- sampleEvent (UUID.toText (UUID.fromWords 9 6 0 1))
    two <- sampleEvent (UUID.toText (UUID.fromWords 9 6 0 2))
    within <- request granted [one] >>= api.publish
    beyond <- request granted [two] >>= try @Rpc.RpcError . api.publish
    pure (within, beyond)
  fmap (^. #outcome) (first ^. #outcomes) === [OUTCOME_ACCEPTED]
  either (\rejected -> rejected.status.code) (const Rpc.Ok) second === Rpc.ResourceExhausted

forwarded :: Property
forwarded = property do
  let context headers = Rpc.Context{metadata = headers, timeout = Nothing, respondWith = const (pure ()), trailWith = const (pure ()), flush = pure (), peer = Nothing, requestPath = "", requestCodec = Rpc.Proto, requestBytes = Nothing}
      trusting = PeerLimit{rate = Rate{perMinute = 60, burst = 1}, forwardedHeader = Just "X-Forwarded-For"}
      distrusting = trusting{forwardedHeader = Nothing}
  peerOf trusting (context (Rpc.header "x-forwarded-for" "203.0.113.7, 198.51.100.2")) === Just "203.0.113.7"
  peerOf trusting (context mempty) === Nothing
  peerOf distrusting (context (Rpc.header "x-forwarded-for" "203.0.113.7")) === Nothing

exposed :: Property
exposed = property do
  (found, body, kind, missing) <- liftIO do
    metrics <- newMetrics
    metrics.gauge Series{name = "insights_projects", labels = []} 3
    manager <- Http.newManager Http.defaultManagerSettings
    testWithApplication (pure (exposing metrics)) \port -> do
      let asking path = Http.parseRequest ("http://127.0.0.1:" <> show port <> path) >>= (`Http.httpLbs` manager)
      answer <- asking "/metrics"
      elsewhere <- asking "/"
      pure (statusCode (Http.responseStatus answer), Http.responseBody answer, lookup "content-type" (Http.responseHeaders answer), statusCode (Http.responseStatus elsewhere))
  found === 200
  kind === Just "text/plain; version=0.0.4; charset=utf-8"
  TE.decodeUtf8Lenient (LBS.toStrict body) === "# HELP insights_projects Environments the server accepts data for.\n# TYPE insights_projects gauge\ninsights_projects 3\n"
  missing === 404

healthJson :: Db -> Property
healthJson db = property do
  status <- liftIO $ withServer db \port -> do
    manager <- Http.newManager Http.defaultManagerSettings
    probe <- Http.parseRequest ("POST http://127.0.0.1:" <> show port <> "/grpc.health.v1.Health/Check")
    statusCode . Http.responseStatus <$> Http.httpLbs probe{Http.requestHeaders = [("content-type", "application/json")], Http.requestBody = Http.RequestBodyLBS "{}"} manager
  assert (status /= 200)
