module Test.Peculiar.Insights.Server.Db
  ( tests
  , project
  , sampleContext
  , itemIdOf
  , eventItem
  , crashItem
  , register
  ) where

import Control.Monad.IO.Class (liftIO)
import Data.Int (Int64)
import Data.Map.Strict qualified as Map
import Data.String (fromString)
import Data.Text qualified as T
import Data.Text.Encoding qualified as TE
import Data.Time (UTCTime, addUTCTime, getCurrentTime)
import Data.UUID.Types qualified as UUID
import Data.Word (Word32)
import Database.PostgreSQL.Simple (Only (..), close, connectPostgreSQL, query, query_)
import Hedgehog
import Peculiar.Insights.Core.Config (Project (..))
import Peculiar.Insights.Core.Config qualified as Config
import Peculiar.Insights.Core.Consent (ConsentState (..), PolicyVersion (..), Purpose (..), PurposeState (..))
import Peculiar.Insights.Core.Item
import Peculiar.Insights.Core.Value (Value (..))
import Peculiar.Insights.Server.Db
import Peculiar.Insights.Server.Maintain (analyticsStatements, cohortStatements)
import Peculiar.Insights.Server.Projects (Registered (..))

project :: Project
project =
  Project
    { slug = "shop"
    , environment = "test"
    , keyFile = ""
    , retentionDays = Just 30
    , rateLimit = Nothing
    , denylist = []
    , cohorts = [Config.Cohort{name = "buyers", conditions = [Config.DidEvent Config.EventCondition{event = "buy", filters = Map.empty, atLeast = 1, withinDays = 30}]}]
    , analytics =
        Just
          Config.Analytics
            { funnels =
                [ Config.Funnel
                    { name = "checkout"
                    , steps = [Config.Step{label = "view", event = "view", filters = Map.empty}, Config.Step{label = "buy", event = "buy", filters = Map.empty}]
                    , windowDays = 7
                    , lookbackDays = 90
                    }
                ]
            , retention =
                [ Config.Retention
                    { name = "weekly"
                    , birth = Config.Matcher{event = "view", filters = Map.empty}
                    , returnEvent = Config.Matcher{event = "buy", filters = Map.empty}
                    , period = Config.Week
                    , periods = 4
                    , lookbackDays = 90
                    }
                ]
            , metrics = [Config.Metric{name = "views", event = "view", filters = Map.empty, measure = Nothing}]
            }
    }

sampleContext :: Context
sampleContext =
  Context
    { sdkName = "test"
    , sdkVersion = "0"
    , appVersion = "1.0.0"
    , appBuild = "100"
    , platform = Ios
    , osName = "iOS"
    , osVersion = "18"
    , deviceModel = "phone"
    , locale = "en"
    , timezone = "UTC"
    , screenWidth = 1
    , screenHeight = 1
    }

itemIdOf :: Word32 -> Word32 -> ItemId
itemIdOf group n = ItemId (UUID.fromWords 7 group 0 n)

eventItem :: (Word32, Word32) -> UTCTime -> T.Text -> T.Text -> Maybe T.Text -> Item
eventItem (group, n) at device name user =
  ItemEvent
    Event
      { id = itemIdOf group n
      , time = at
      , subject = Subject{device = DeviceId device, user = UserId <$> user, session = SessionId (device <> "-s")}
      , context = sampleContext
      , name
      , properties = Map.fromList [("n", VInt (fromIntegral n))]
      }

crashItem :: Word32 -> Word32 -> UTCTime -> T.Text -> Item
crashItem group n at device =
  ItemCrashReport
    CrashReport
      { id = itemIdOf group n
      , time = at
      , subject = Subject{device = DeviceId device, user = Nothing, session = SessionId (device <> "-s")}
      , context = sampleContext
      , exceptionType = "StateError"
      , message = "bad state " <> T.pack (show n)
      , frames = [Frame{moduleName = "app", function = "main", file = "main.dart", line = n, column = 1, inApp = True, instructionAddress = Nothing, image = Nothing}]
      , rawStackTrace = "raw"
      , fatal = True
      , thread = "main"
      , customKeys = Map.empty
      , logs = []
      }

register :: Db -> IO Registered
register db =
  db.registerProjects [project] >>= \case
    Right [one] -> pure one
    other -> ioError (userError ("registering the project: " <> show other))

count :: T.Text -> T.Text -> [T.Text] -> IO Int64
count conninfo sql params = do
  connection <- connectPostgreSQL (TE.encodeUtf8 conninfo)
  rows <- if null params then query_ connection (fromString' sql) else query connection (fromString' sql) params
  close connection
  pure case rows of
    [Only n] -> n
    _ -> -1
 where
  fromString' = fromString . T.unpack

tests :: T.Text -> Db -> Group
tests conninfo db =
  Group
    "Db"
    [ ("migrating and verifying the schema", withTests 1 (migrating db))
    , ("a repeated item is a duplicate", withTests 1 (duplicated db))
    , ("identify backfills the device's anonymous events", withTests 1 (backfilled conninfo db))
    , ("crashes with the same shape share an issue", withTests 1 (grouped conninfo db))
    , ("consent is recorded once", withTests 1 (consented conninfo db))
    , ("erasure removes the device's data", withTests 1 (erased conninfo db))
    , ("retention deletes past the cutoff", withTests 1 (retained conninfo db))
    , ("the funnel function counts a converted person", withTests 1 (funnel conninfo db))
    , ("declared cohorts and analytics install as views", withTests 1 (declared conninfo db))
    ]

migrating :: Db -> Property
migrating db = property do
  first <- liftIO db.migrateSchema
  first === Right ()
  again <- liftIO db.migrateSchema
  again === Right ()
  verified <- liftIO db.verify
  verified === Right ()

duplicated :: Db -> Property
duplicated db = property do
  registered <- liftIO (register db)
  now <- liftIO getCurrentTime
  let item = eventItem (1, 1) now "dup-device" "open" Nothing
  first <- liftIO (db.publish registered now [item] Map.empty)
  first === Right [Stored (itemIdOf 1 1)]
  second <- liftIO (db.publish registered now [item, eventItem (1, 2) now "dup-device" "open" Nothing] Map.empty)
  second === Right [Duplicate (itemIdOf 1 1), Stored (itemIdOf 1 2)]

backfilled :: T.Text -> Db -> Property
backfilled conninfo db = property do
  registered <- liftIO (register db)
  now <- liftIO getCurrentTime
  _ <- liftIO (db.publish registered now [eventItem (2, 1) now "anon-device" "open" Nothing] Map.empty)
  anonymous <- liftIO (count conninfo "SELECT count(*) FROM event WHERE device_id = ? AND person_id IS NULL" ["anon-device"])
  anonymous === 1
  _ <- liftIO (db.publish registered now [ItemIdentify Identify{id = itemIdOf 2 2, time = now, device = DeviceId "anon-device", user = UserId "alice"}] Map.empty)
  linked <- liftIO (count conninfo "SELECT count(*) FROM event WHERE device_id = ? AND person_id IS NOT NULL" ["anon-device"])
  linked === 1
  people <- liftIO (count conninfo "SELECT count(*) FROM person WHERE user_id = ?" ["alice"])
  people === 1

grouped :: T.Text -> Db -> Property
grouped conninfo db = property do
  registered <- liftIO (register db)
  now <- liftIO getCurrentTime
  stored <- liftIO (db.publish registered now [crashItem 3 1 now "crash-device", crashItem 3 2 now "crash-device"] Map.empty)
  stored === Right [Stored (itemIdOf 3 1), Stored (itemIdOf 3 2)]
  issues <- liftIO (count conninfo "SELECT count(*) FROM issue WHERE exception_type = 'StateError'" [])
  issues === 1
  crashes <- liftIO (count conninfo "SELECT count(*) FROM crash WHERE device_id = ?" ["crash-device"])
  crashes === 2
  crashed <- liftIO (count conninfo "SELECT count(*) FROM session WHERE device_id = ? AND crashed" ["crash-device"])
  crashed === 1

consented :: T.Text -> Db -> Property
consented conninfo db = property do
  registered <- liftIO (register db)
  now <- liftIO getCurrentTime
  let record =
        ConsentRecord
          { id = itemIdOf 4 1
          , time = now
          , device = DeviceId "consent-device"
          , user = Nothing
          , purpose = Analytics
          , state = PurposeState{state = Granted, policyVersion = PolicyVersion "v1"}
          }
  first <- liftIO (db.recordConsent registered now record)
  first === Right (Stored (itemIdOf 4 1))
  second <- liftIO (db.recordConsent registered now record)
  second === Right (Duplicate (itemIdOf 4 1))
  rows <- liftIO (count conninfo "SELECT count(*) FROM consent WHERE device_id = ?" ["consent-device"])
  rows === 1

erased :: T.Text -> Db -> Property
erased conninfo db = property do
  registered <- liftIO (register db)
  now <- liftIO getCurrentTime
  _ <- liftIO (db.publish registered now [eventItem (5, 1) now "gone-device" "open" (Just "bob"), eventItem (5, 2) now "gone-device" "buy" (Just "bob")] Map.empty)
  before <- liftIO (count conninfo "SELECT count(*) FROM event WHERE device_id = ?" ["gone-device"])
  before === 2
  outcome <- liftIO (db.erase registered now ErasureRequest{id = itemIdOf 5 3, time = now, device = DeviceId "gone-device", user = Just (UserId "bob")})
  outcome === Right Erased
  after <- liftIO (count conninfo "SELECT count(*) FROM event WHERE device_id = ?" ["gone-device"])
  after === 0
  people <- liftIO (count conninfo "SELECT count(*) FROM person WHERE user_id = ?" ["bob"])
  people === 0
  recorded <- liftIO (count conninfo "SELECT count(*) FROM erasure WHERE device_id = ?" ["gone-device"])
  recorded === 1

retained :: T.Text -> Db -> Property
retained conninfo db = property do
  registered <- liftIO (register db)
  now <- liftIO getCurrentTime
  let old = addUTCTime (negate (10 * 86400)) now
  _ <- liftIO (db.publish registered now [eventItem (6, 1) old "old-device" "open" Nothing, eventItem (6, 2) now "old-device" "open" Nothing] Map.empty)
  outcome <- liftIO (db.retain now [Retention{registered, cutoff = addUTCTime (negate (5 * 86400)) now}])
  outcome === Right ()
  remaining <- liftIO (count conninfo "SELECT count(*) FROM event WHERE device_id = ?" ["old-device"])
  remaining === 1

funnel :: T.Text -> Db -> Property
funnel conninfo db = property do
  registered <- liftIO (register db)
  now <- liftIO getCurrentTime
  _ <-
    liftIO
      ( db.publish
          registered
          now
          [ eventItem (7, 1) (addUTCTime (negate 300) now) "funnel-a" "view" Nothing
          , eventItem (7, 2) (addUTCTime (negate 200) now) "funnel-a" "buy" Nothing
          , eventItem (7, 3) (addUTCTime (negate 300) now) "funnel-b" "view" Nothing
          ]
          Map.empty
      )
  connection <- liftIO (connectPostgreSQL (TE.encodeUtf8 conninfo))
  rows <-
    liftIO
      ( query
          connection
          "SELECT step, people FROM reporting.funnel(?, ?, ARRAY['view', 'buy'], interval '1 hour', now() - interval '1 day', now() + interval '1 day')"
          ("shop" :: T.Text, "test" :: T.Text)
      )
  liftIO (close connection)
  (rows :: [(Int, Int64)]) === [(1, 2), (2, 1)]

declared :: T.Text -> Db -> Property
declared conninfo db = property do
  registered <- liftIO (register db)
  installed <- liftIO (db.execute (cohortStatements [registered] <> analyticsStatements [registered]))
  installed === Right ()
  views <- liftIO (count conninfo "SELECT count(*) FROM information_schema.views WHERE table_schema = 'reporting' AND table_name IN ('cohort_shop_test_buyers', 'funnel_shop_test_checkout', 'retention_shop_test_weekly', 'metric_shop_test_views')" [])
  views === 4
  funnelRows <- liftIO (count conninfo "SELECT count(*) FROM reporting.funnel_shop_test_checkout" [])
  funnelRows === 2
  metricRows <- liftIO (count conninfo "SELECT count(*) FROM reporting.metric_shop_test_views" [])
  assert (metricRows >= 0)
