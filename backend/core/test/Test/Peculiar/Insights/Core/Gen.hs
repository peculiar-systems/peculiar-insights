module Test.Peculiar.Insights.Core.Gen
  ( identifier
  , name
  , value
  , shallowValue
  , utcTime
  , uuid
  , anItemId
  , subject
  , context
  , frame
  , image
  , event
  , identify
  , profileUpdate
  , crashReport
  , item
  , snapshot
  , grantedAll
  ) where

import Data.Map.Strict qualified as Map
import Data.Text qualified as T
import Data.Time (UTCTime (..), fromGregorian, secondsToDiffTime)
import Data.UUID.Types (UUID)
import Data.UUID.Types qualified as UUID
import Data.Word (Word64)
import Hedgehog (Gen)
import Hedgehog.Gen qualified as Gen
import Hedgehog.Range qualified as Range
import Peculiar.Insights.Core.Consent
import Peculiar.Insights.Core.Enum (enumerate)
import Peculiar.Insights.Core.Item
import Peculiar.Insights.Core.Value (Value (..))

identifier :: Gen T.Text
identifier = Gen.text (Range.linear 1 32) Gen.alphaNum

name :: Gen T.Text
name = Gen.text (Range.linear 1 40) (Gen.frequency [(9, Gen.alphaNum), (1, pure '_')])

shallowValue :: Gen Value
shallowValue =
  Gen.choice
    [ VString <$> Gen.text (Range.linear 0 40) Gen.unicode
    , VInt <$> Gen.int64 Range.linearBounded
    , VDouble <$> Gen.double (Range.linearFrac (-1e6) 1e6)
    , VBool <$> Gen.bool
    , VTime <$> utcTime
    ]

value :: Gen Value
value = valueUpTo 3

valueUpTo :: Int -> Gen Value
valueUpTo depth
  | depth <= 0 = shallowValue
  | otherwise =
      Gen.frequency
        [ (3, shallowValue)
        , (1, VList <$> Gen.list (Range.linear 0 3) (valueUpTo (depth - 1)))
        , (1, VMap . Map.fromList <$> Gen.list (Range.linear 0 3) ((,) <$> identifier <*> valueUpTo (depth - 1)))
        ]

utcTime :: Gen UTCTime
utcTime = do
  day <- fromGregorian <$> Gen.integral (Range.linear 2020 2030) <*> Gen.int (Range.linear 1 12) <*> Gen.int (Range.linear 1 28)
  seconds <- Gen.integral (Range.linear 0 86399)
  pure (UTCTime day (secondsToDiffTime seconds))

uuid :: Gen UUID
uuid = UUID.fromWords <$> Gen.word32 Range.linearBounded <*> Gen.word32 Range.linearBounded <*> Gen.word32 Range.linearBounded <*> Gen.word32 Range.linearBounded

anItemId :: Gen ItemId
anItemId = ItemId <$> uuid

subject :: Gen Subject
subject = Subject . DeviceId <$> identifier <*> Gen.maybe (UserId <$> identifier) <*> (SessionId <$> identifier)

context :: Gen Context
context =
  Context
    <$> identifier
    <*> identifier
    <*> identifier
    <*> identifier
    <*> Gen.enumBounded
    <*> identifier
    <*> identifier
    <*> identifier
    <*> identifier
    <*> identifier
    <*> Gen.word32 (Range.linear 0 4096)
    <*> Gen.word32 (Range.linear 0 4096)

properties :: Gen (Map.Map T.Text Value)
properties = Map.fromList <$> Gen.list (Range.linear 0 8) ((,) <$> identifier <*> value)

frame :: Gen Frame
frame =
  Frame
    <$> identifier
    <*> identifier
    <*> identifier
    <*> Gen.word32 (Range.linear 0 10000)
    <*> Gen.word32 (Range.linear 0 200)
    <*> Gen.bool
    <*> Gen.maybe address
    <*> Gen.maybe image

image :: Gen Image
image = Image <$> identifier <*> identifier <*> address

address :: Gen Word64
address = Gen.word64 Range.constantBounded

event :: Gen Event
event = Event <$> anItemId <*> utcTime <*> subject <*> context <*> name <*> properties

identify :: Gen Identify
identify = Identify <$> anItemId <*> utcTime <*> (DeviceId <$> identifier) <*> (UserId <$> identifier)

profileUpdate :: Gen ProfileUpdate
profileUpdate = ProfileUpdate <$> anItemId <*> utcTime <*> (DeviceId <$> identifier) <*> (UserId <$> identifier) <*> Gen.list (Range.linear 0 8) operation
 where
  operation =
    Gen.choice
      [ Set <$> identifier <*> value
      , SetOnce <$> identifier <*> value
      , Unset <$> identifier
      , Increment <$> identifier <*> Gen.double (Range.linearFrac (-100) 100)
      ]

crashReport :: Gen CrashReport
crashReport =
  CrashReport
    <$> anItemId
    <*> utcTime
    <*> subject
    <*> context
    <*> identifier
    <*> Gen.text (Range.linear 0 200) Gen.unicode
    <*> Gen.list (Range.linear 0 12) frame
    <*> Gen.text (Range.linear 0 400) Gen.unicode
    <*> Gen.bool
    <*> identifier
    <*> properties
    <*> Gen.list (Range.linear 0 8) (LogLine <$> utcTime <*> Gen.enumBounded <*> Gen.text (Range.linear 0 100) Gen.unicode)

item :: Gen Item
item =
  Gen.choice
    [ ItemEvent <$> event
    , ItemIdentify <$> identify
    , ItemProfileUpdate <$> profileUpdate
    , ItemCrashReport <$> crashReport
    ]

snapshot :: Gen Snapshot
snapshot = Snapshot . Map.fromList <$> Gen.subsequence [(purpose, PurposeState state (PolicyVersion "v1")) | purpose <- enumerate, state <- enumerate]

grantedAll :: Snapshot
grantedAll = Snapshot (Map.fromList [(purpose, PurposeState Granted (PolicyVersion "v1")) | purpose <- enumerate])
