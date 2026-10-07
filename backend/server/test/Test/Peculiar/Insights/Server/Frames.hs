module Test.Peculiar.Insights.Server.Frames
  ( tests
  , protoFrame
  ) where

import Control.Exception (bracket)
import Control.Monad.IO.Class (liftIO)
import Data.Aeson qualified as Aeson
import Data.ProtoLens (defMessage)
import Data.ProtoLens.Labels ()
import Data.Text qualified as T
import Data.Text.Encoding qualified as TE
import Data.Time (getCurrentTime)
import Data.Time.Clock.POSIX (utcTimeToPOSIXSeconds)
import Data.UUID.Types qualified as UUID
import Database.PostgreSQL.Simple (Only (..), close, connectPostgreSQL, query)
import Hedgehog
import Lens.Family2 ((&), (.~), (^.))
import Peculiar.Insights.Core.Item (Frame (..), Image (..))
import Peculiar.Insights.Core.Validate (Limits (..), defaultLimits)
import Peculiar.Insights.Server.Api (IngestClient (..))
import Peculiar.Insights.Server.Db (Db)
import Proto.Peculiar.Insights.V1.Common (Platform (..))
import Proto.Peculiar.Insights.V1.Ingest (Outcome (..))
import Proto.Peculiar.Insights.V1.Ingest qualified as P
import Test.Peculiar.Insights.Server.Harness (granted, remote, request, withServer)

tests :: T.Text -> Db -> Group
tests conninfo db =
  Group
    "Frames"
    [ ("frame addresses and images read back from the crash view", withTests 1 (addressed conninfo db))
    ]

addressed :: T.Text -> Db -> Property
addressed conninfo db = property do
  let kept = UUID.fromWords 9 7 0 1
      refusedId = UUID.fromWords 9 7 0 2
      overlong = T.replicate (defaultLimits.maxIdentifierLength + 1) "f"
  (response, stored) <- liftIO do
    answer <- withServer db \port -> do
      api <- remote port (Just "test-key")
      item <- crashCarrying (UUID.toText kept) (fmap protoFrame symbolicable)
      invalid <- crashCarrying (UUID.toText refusedId) [protoFrame (nativeFrame overlong)]
      request granted [item, invalid] >>= api.publish
    rows <- bracket (connectPostgreSQL (TE.encodeUtf8 conninfo)) close \connection ->
      query connection "SELECT frames FROM reporting.crash WHERE id = ?" (Only kept)
    pure (answer, rows)
  fmap (^. #outcome) (response ^. #outcomes) === [OUTCOME_ACCEPTED, OUTCOME_INVALID]
  fmap (\(Only frames) -> Aeson.fromJSON frames) stored === [Aeson.Success symbolicable]

symbolicable :: [Frame]
symbolicable =
  [ nativeFrame "4c4c4447e8d4b7f2a1c0e3e5d0b6a9f1"
  , Frame
      { moduleName = "https://shop.example.org/main.dart.js"
      , function = "a.b"
      , file = "main.dart.js"
      , line = 2
      , column = 4810
      , inApp = True
      , instructionAddress = Nothing
      , image = Nothing
      }
  ]

nativeFrame :: T.Text -> Frame
nativeFrame identifier =
  Frame
    { moduleName = ""
    , function = ""
    , file = ""
    , line = 0
    , column = 0
    , inApp = True
    , instructionAddress = Just 0xffffff8000123456
    , image = Just Image{name = "libapp.so", identifier, loadAddress = 0xffffff8000000000}
    }

protoFrame :: Frame -> P.Frame
protoFrame frame =
  defMessage
    & #module' .~ frame.moduleName
    & #function .~ frame.function
    & #file .~ frame.file
    & #line .~ frame.line
    & #column .~ frame.column
    & #inApp .~ frame.inApp
    & #maybe'instructionAddress .~ frame.instructionAddress
    & #maybe'image .~ fmap protoImage frame.image
 where
  protoImage image = defMessage & #name .~ image.name & #identifier .~ image.identifier & #loadAddress .~ image.loadAddress

crashCarrying :: T.Text -> [P.Frame] -> IO P.Item
crashCarrying identifier frames = do
  now <- getCurrentTime
  let stamp = defMessage & #seconds .~ floor (utcTimeToPOSIXSeconds now)
      subject = defMessage & #deviceId .~ "api-crash-device" & #sessionId .~ "api-crash-session"
      context = defMessage & #sdkName .~ "test" & #appBuild .~ "1" & #platform .~ PLATFORM_ANDROID
      crash = defMessage & #id .~ identifier & #time .~ stamp & #subject .~ subject & #context .~ context & #exceptionType .~ "SIGSEGV" & #fatal .~ True & #frames .~ frames
  pure (defMessage & #crashReport .~ crash)
