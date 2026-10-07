module Test.Peculiar.Insights.Core.RateLimit (tests) where

import Data.Time (UTCTime (..), addUTCTime, diffUTCTime, fromGregorian)
import Hedgehog
import Hedgehog.Gen qualified as Gen
import Hedgehog.Range qualified as Range
import Peculiar.Insights.Core.Config (Rate (..))
import Peculiar.Insights.Core.RateLimit

tests :: Group
tests =
  Group
    "RateLimit"
    [ ("what is allowed never exceeds the burst plus what refilled", bounded)
    , ("waiting as long as told is enough", honoured)
    , ("a batch larger than the burst passes a full bucket", oversized)
    , ("the pushback is never zero and never past five minutes", pushback)
    ]

start :: UTCTime
start = UTCTime (fromGregorian 2026 1 1) 0

rates :: Gen Rate
rates = Rate <$> Gen.int (Range.linear 1 6000) <*> Gen.int (Range.linear 1 2000)

bounded :: Property
bounded = property do
  rate <- forAll rates
  requests <- forAll (Gen.list (Range.linear 1 200) ((,) <$> Gen.int (Range.linear 0 5000) <*> Gen.int (Range.linear 1 50)))
  let step (now, bucket, allowed) (gapMillis, cost) =
        let at = addUTCTime (fromIntegral gapMillis / 1000) now
            (verdict, next) = spend rate at cost bucket
         in (at, next, if verdict == Allowed then allowed + min cost rate.burst else allowed)
      (finished, _, total) = foldl' step (start, full rate start, 0) requests
      elapsed = realToFrac (diffUTCTime finished start) :: Double
      ceilingOf = fromIntegral rate.burst + elapsed * fromIntegral rate.perMinute / 60
  assert (fromIntegral total <= ceilingOf + 0.001)

honoured :: Property
honoured = property do
  rate <- forAll rates
  cost <- forAll (Gen.int (Range.linear 1 3000))
  drained <- forAll (Gen.int (Range.linear 1 3000))
  let (_, bucket) = spend rate start drained (full rate start)
  case spend rate start cost bucket of
    (Allowed, _) -> success
    (Limited wait, held) -> do
      assert (wait > 0)
      fst (spend rate (addUTCTime (wait + 0.001) start) cost held) === Allowed

oversized :: Property
oversized = property do
  rate <- forAll rates
  extra <- forAll (Gen.int (Range.linear 1 1000))
  fst (spend rate start (rate.burst + extra) (full rate start)) === Allowed

pushback :: Property
pushback = property do
  seconds <- forAll (Gen.double (Range.linearFrac 0 100000))
  let millis = pushbackMillis (realToFrac seconds)
  assert (millis >= 250 && millis <= 300000)
