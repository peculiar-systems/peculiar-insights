module Test.Peculiar.Insights.Core.Time (tests) where

import Data.Time (addUTCTime)
import Hedgehog
import Hedgehog.Gen qualified as Gen
import Hedgehog.Range qualified as Range
import Peculiar.Insights.Core.Time
import Test.Peculiar.Insights.Core.Gen qualified as Gen

tests :: Group
tests =
  Group
    "Time"
    [ ("correcting the sent-at time yields the receive time", correctingSentAt)
    , ("an item within the window is accepted", insideWindow)
    , ("an item older than the window is stale", olderThanWindow)
    , ("an item beyond the future allowance is future", beyondFuture)
    ]

correctingSentAt :: Property
correctingSentAt = property do
  sentAt <- forAll Gen.utcTime
  receivedAt <- forAll Gen.utcTime
  correct (skewBetween receivedAt sentAt) sentAt === receivedAt

insideWindow :: Property
insideWindow = property do
  now <- forAll Gen.utcTime
  back <- forAll (Gen.integral (Range.linear 0 (90 * 86400)))
  withinWindow defaultWindow now (addUTCTime (negate (fromInteger back)) now) === Right ()

olderThanWindow :: Property
olderThanWindow = property do
  now <- forAll Gen.utcTime
  back <- forAll (Gen.integral (Range.linear (90 * 86400 + 1) (400 * 86400)))
  withinWindow defaultWindow now (addUTCTime (negate (fromInteger back)) now) === Left Stale

beyondFuture :: Property
beyondFuture = property do
  now <- forAll Gen.utcTime
  ahead <- forAll (Gen.integral (Range.linear 301 86400))
  withinWindow defaultWindow now (addUTCTime (fromInteger ahead) now) === Left Future
