module Test.Peculiar.Insights.Core.Ingest (tests) where

import Data.Map.Strict qualified as Map
import Data.Time (addUTCTime)
import Hedgehog
import Hedgehog.Gen qualified as Gen
import Hedgehog.Range qualified as Range
import Peculiar.Insights.Core.Consent
import Peculiar.Insights.Core.Ingest
import Peculiar.Insights.Core.Item
import Peculiar.Insights.Core.Time
import Peculiar.Insights.Core.Validate (defaultLimits)
import Test.Peculiar.Insights.Core.Gen qualified as Gen

tests :: Group
tests =
  Group
    "Ingest"
    [ ("a consented item inside the window is accepted with corrected time", acceptedCorrected)
    , ("an item is refused when its purpose is not granted", refusedWithoutConsent)
    , ("consent is checked per purpose", perPurpose)
    , ("a stale item is rejected after correction", staleRejected)
    ]

acceptedCorrected :: Property
acceptedCorrected = property do
  item <- forAll Gen.item
  now <- forAll Gen.utcTime
  drift <- forAll (Gen.integral (Range.linear (-3600) 3600))
  let sentAt = addUTCTime (fromInteger drift) now
      skew = skewBetween now sentAt
      shifted = setTime sentAt item
  plan Policy{limits = defaultLimits, window = defaultWindow, consent = Gen.grantedAll, skew, now} shifted === Accepted (setTime now item)

refusedWithoutConsent :: Property
refusedWithoutConsent = property do
  item <- forAll Gen.item
  now <- forAll Gen.utcTime
  let snapshot = Snapshot Map.empty
  plan Policy{limits = defaultLimits, window = defaultWindow, consent = snapshot, skew = Skew 0, now} item === Rejected (itemId item) (NotConsented (itemPurpose item))

perPurpose :: Property
perPurpose = property do
  item <- forAll Gen.item
  snapshot <- forAll Gen.snapshot
  now <- forAll Gen.utcTime
  let outcome = plan Policy{limits = defaultLimits, window = defaultWindow, consent = snapshot, skew = Skew 0, now} (setTime now item)
  case outcome of
    Accepted _ -> assert (permits snapshot (itemPurpose item))
    Rejected _ (NotConsented purpose) -> do
      purpose === itemPurpose item
      assert (not (permits snapshot purpose))
    other -> annotateShow other *> failure

staleRejected :: Property
staleRejected = property do
  item <- forAll Gen.item
  now <- forAll Gen.utcTime
  back <- forAll (Gen.integral (Range.linear (91 * 86400) (400 * 86400)))
  let old = setTime (addUTCTime (negate (fromInteger back)) now) item
  plan Policy{limits = defaultLimits, window = defaultWindow, consent = Gen.grantedAll, skew = Skew 0, now} old === Rejected (itemId item) (OutOfWindow Stale)
