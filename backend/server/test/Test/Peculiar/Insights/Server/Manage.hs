module Test.Peculiar.Insights.Server.Manage
  ( tests
  ) where

import Control.Exception (bracket, try)
import Control.Monad (void)
import Control.Monad.IO.Class (liftIO)
import Crypto.JWT (Crv (P_256), JWK, JWKSet (..), JWTError (..), KeyMaterialGenParam (ECGenParam), SignedJWT, encodeCompact, genJWK, makeJWSHeader, runJOSE, signJWT)
import Data.Aeson (ToJSON)
import Data.ByteString qualified as BS
import Data.ByteString.Lazy qualified as LBS
import Data.Int (Int64)
import Data.Map.Strict qualified as Map
import Data.ProtoLens (Message, defMessage)
import Data.ProtoLens.Field (HasField)
import Data.ProtoLens.Labels ()
import Data.Text qualified as T
import Data.Text.Encoding qualified as TE
import Data.Time (UTCTime, addUTCTime, getCurrentTime)
import Data.Time.Clock.POSIX (utcTimeToPOSIXSeconds)
import Database.PostgreSQL.Simple (Connection, Only (..), close, connectPostgreSQL, query, query_)
import GHC.Generics (Generic, Generically (..))
import Hedgehog
import Lens.Family2 ((&), (.~), (^.))
import Peculiar.Insights.Core.Item
import Peculiar.Insights.Server.Api (IngestClient (..))
import Peculiar.Insights.Server.Db (Db (..))
import Peculiar.Insights.Server.Grafana (Grafana (..), Refusal (..), absentGrafana, admit)
import Peculiar.Insights.Server.Manage (ManageClient (..))
import Peculiar.Rpc qualified as Rpc
import Test.Peculiar.Insights.Server.Db (itemIdOf, register, sampleContext)
import Test.Peculiar.Insights.Server.Harness (granted, managing, remote, remoteJson, request, sampleEvent, withManaged)

data Issued = Issued
  { aud :: [T.Text]
  , exp :: Int64
  , role :: Maybe T.Text
  }
  deriving stock (Generic)
  deriving (ToJSON) via Generically Issued

data Signer = Signer
  { key :: JWK
  , grafana :: Grafana
  }

tests :: T.Text -> Db -> IO Group
tests conninfo db = do
  signer <- newSigner
  stranger <- genJWK (ECGenParam P_256)
  pure
    ( Group
        "Manage"
        [ ("only an Admin's identity in the organization is admitted", withTests 1 (admitting signer stranger))
        , ("an Admin resolves, reopens and ignores an issue, and a missing one is not found", withTests 1 (triaging conninfo db signer))
        , ("an Editor, a Viewer, no identity and no Grafana change nothing", withTests 1 (refusing conninfo db signer))
        , ("an Admin erases a person, leaving only the erasure", withTests 1 (erasing conninfo db signer))
        , ("JSON reaches no ingest method, and binary protobuf still does", withTests 1 (codecs db))
        ]
    )

newSigner :: IO Signer
newSigner = do
  key <- genJWK (ECGenParam P_256)
  pure Signer{key, grafana = Grafana{organization = 1, signingKeys = pure (Right (JWKSet [key]))}}

token :: JWK -> UTCTime -> T.Text -> Maybe T.Text -> IO BS.ByteString
token key expiry audience role = do
  signed <- runJOSE @JWTError do
    header <- makeJWSHeader key
    signJWT key header Issued{aud = [audience], exp = floor (utcTimeToPOSIXSeconds expiry), role}
  either (ioError . userError . show) (pure . LBS.toStrict . encodeCompact @SignedJWT) signed

as :: Signer -> Maybe T.Text -> IO BS.ByteString
as signer role = do
  now <- getCurrentTime
  token signer.key (addUTCTime 600 now) "org:1" role

admitting :: Signer -> JWK -> Property
admitting signer stranger = property do
  now <- liftIO getCurrentTime
  let keys = JWKSet [signer.key]
      later = addUTCTime 600 now
  admin <- liftIO (token signer.key later "org:1" (Just "Admin"))
  editor <- liftIO (token signer.key later "org:1" (Just "Editor"))
  viewer <- liftIO (token signer.key later "org:1" (Just "Viewer"))
  roleless <- liftIO (token signer.key later "org:1" Nothing)
  elsewhere <- liftIO (token signer.key later "org:2" (Just "Admin"))
  expired <- liftIO (token signer.key (addUTCTime (-600) now) "org:1" (Just "Admin"))
  forged <- liftIO (token stranger later "org:1" (Just "Admin"))
  admit 1 now keys admin === Right ()
  admit 1 now keys editor === Left (NotAdmin (Just "Editor"))
  admit 1 now keys viewer === Left (NotAdmin (Just "Viewer"))
  admit 1 now keys roleless === Left (NotAdmin Nothing)
  admit 1 now keys elsewhere === Left (Unverified JWTNotInAudience)
  admit 1 now keys expired === Left (Unverified JWTExpired)
  assert (admit 1 now keys forged /= Right ())
  assert (admit 1 now keys "not a token" /= Right ())

connected :: T.Text -> (Connection -> IO a) -> IO a
connected conninfo = bracket (connectPostgreSQL (TE.encodeUtf8 conninfo)) close

crashing :: Db -> Word -> T.Text -> IO ()
crashing db n message = do
  now <- getCurrentTime
  registered <- register db
  void (db.publish registered now [crash now] Map.empty)
 where
  crash at =
    ItemCrashReport
      CrashReport
        { id = itemIdOf 60 (fromIntegral n)
        , time = at
        , subject = Subject{device = DeviceId "manage-phone", user = Nothing, session = SessionId "manage-s"}
        , context = sampleContext
        , exceptionType = "LedgerError" <> T.pack (show n)
        , message
        , frames = [Frame{moduleName = "ledger", function = "close" <> T.pack (show n), file = "ledger.dart", line = 9, column = 1, inApp = True, instructionAddress = Nothing, image = Nothing}]
        , rawStackTrace = "raw"
        , fatal = True
        , thread = "main"
        , customKeys = Map.empty
        , logs = []
        }

issueOf :: T.Text -> T.Text -> PropertyT IO Int64
issueOf conninfo message = do
  found <- liftIO (connected conninfo \connection -> query connection "SELECT DISTINCT issue_id FROM crash WHERE message = ?" (Only message))
  case found of
    [Only issue] -> pure issue
    other -> annotateShow other *> failure

stateOf :: T.Text -> Int64 -> PropertyT IO (T.Text, Maybe T.Text)
stateOf conninfo issue = do
  found <- liftIO (connected conninfo \connection -> query connection "SELECT state, resolved_build FROM issue WHERE id = ?" (Only issue))
  case found of
    [row] -> pure row
    other -> annotateShow other *> failure

aimed :: (Message request, HasField request "project" T.Text, HasField request "environment" T.Text, HasField request "issue" Int64) => Int64 -> request
aimed issue = defMessage & #project .~ "shop" & #environment .~ "test" & #issue .~ issue

codeOf :: IO a -> IO Rpc.Code
codeOf call = either (\rejected -> rejected.status.code) (const Rpc.Ok) <$> try @Rpc.RpcError call

triaging :: T.Text -> Db -> Signer -> Property
triaging conninfo db signer = property do
  liftIO (crashing db 1 "the ledger is torn")
  issue <- issueOf conninfo "the ledger is torn"
  identity <- liftIO (as signer (Just "Admin"))
  let states = connected conninfo \connection -> query connection "SELECT state, resolved_build FROM issue WHERE id = ?" (Only issue)
  (resolved, reopened, ignored, missing) <- liftIO $ withManaged db signer.grafana \port -> do
    api <- managing port (Just identity)
    resolved <- codeOf (api.resolveIssue (aimed issue)) *> states
    reopened <- codeOf (api.reopenIssue (aimed issue)) *> states
    ignored <- codeOf (api.ignoreIssue (aimed issue)) *> states
    missing <- codeOf (api.resolveIssue (aimed 987654321))
    pure (resolved, reopened, ignored, missing)
  resolved === [("resolved" :: T.Text, Just ("100" :: T.Text))]
  reopened === [("open", Nothing)]
  ignored === [("ignored", Nothing)]
  missing === Rpc.NotFound

refusing :: T.Text -> Db -> Signer -> Property
refusing conninfo db signer = property do
  liftIO (crashing db 2 "the abacus slipped")
  issue <- issueOf conninfo "the abacus slipped"
  before <- stateOf conninfo issue
  editor <- liftIO (as signer (Just "Editor"))
  viewer <- liftIO (as signer (Just "Viewer"))
  admin <- liftIO (as signer (Just "Admin"))
  let attempts port identity = do
        api <- managing port identity
        traverse
          codeOf
          [ void (api.resolveIssue (aimed issue))
          , void (api.ignoreIssue (aimed issue))
          , void (api.reopenIssue (aimed issue))
          , void (api.erasePerson (defMessage & #project .~ "shop" & #environment .~ "test" & #userId .~ "nobody"))
          ]
  refused <- liftIO $ withManaged db signer.grafana \port ->
    (,,) <$> attempts port (Just editor) <*> attempts port (Just viewer) <*> attempts port Nothing
  unlinked <- liftIO $ withManaged db absentGrafana \port -> attempts port (Just admin)
  refused === (replicate 4 Rpc.PermissionDenied, replicate 4 Rpc.PermissionDenied, replicate 4 Rpc.Unauthenticated)
  unlinked === replicate 4 Rpc.FailedPrecondition
  stateOf conninfo issue >>= (=== before)

erasing :: T.Text -> Db -> Signer -> Property
erasing conninfo db signer = property do
  now <- liftIO getCurrentTime
  registered <- liftIO (register db)
  let subject = Subject{device = DeviceId "erin-phone", user = Just (UserId "erin"), session = SessionId "erin-s"}
      seen = ItemEvent Event{id = itemIdOf 61 1, time = now, subject, context = sampleContext, name = "open", properties = Map.empty}
      named = ItemIdentify Identify{id = itemIdOf 61 2, time = now, device = DeviceId "erin-phone", user = UserId "erin"}
  _ <- liftIO (db.publish registered now [named, seen] Map.empty)
  editor <- liftIO (as signer (Just "Editor"))
  admin <- liftIO (as signer (Just "Admin"))
  found <- liftIO (connected conninfo (`query_` "SELECT id FROM person WHERE user_id = 'erin'"))
  erin <- case found of
    [Only (identifier :: Int64)] -> pure identifier
    other -> annotateShow other *> failure
  let person = defMessage & #project .~ "shop" & #environment .~ "test" & #userId .~ "erin"
      traces = connected conninfo \connection -> query connection "SELECT (SELECT count(*) FROM person WHERE id = ?), (SELECT count(*) FROM event WHERE person_id = ?), (SELECT count(*) FROM device WHERE person_id = ?), (SELECT count(*) FROM erasure WHERE person_id = ?)" (erin, erin, erin, erin)
  (refused, kept, erased, again) <- liftIO $ withManaged db signer.grafana \port -> do
    asEditor <- managing port (Just editor)
    asAdmin <- managing port (Just admin)
    refused <- codeOf (asEditor.erasePerson person)
    kept <- traces
    erased <- codeOf (asAdmin.erasePerson person)
    again <- codeOf (asAdmin.erasePerson person)
    pure (refused, kept, erased, again)
  refused === Rpc.PermissionDenied
  kept === [(1 :: Int64, 1 :: Int64, 1 :: Int64, 0 :: Int64)]
  erased === Rpc.Ok
  again === Rpc.NotFound
  left <- liftIO traces
  left === [(0, 0, 0, 1)]

codecs :: Db -> Property
codecs db = property do
  item <- liftIO (sampleEvent "00000000-0000-0009-0000-000000000077")
  body <- liftIO (request granted [item])
  (json, binary) <- liftIO $ withManaged db absentGrafana \port -> do
    asJson <- remoteJson port "test-key"
    asBinary <- remote port (Just "test-key")
    json <-
      traverse
        codeOf
        [ void (asJson.publish body)
        , void (asJson.recordConsent defMessage)
        , void (asJson.requestErasure defMessage)
        ]
    binary <- asBinary.publish body
    pure (json, binary)
  json === replicate 3 Rpc.InvalidArgument
  length (binary ^. #outcomes) === 1
