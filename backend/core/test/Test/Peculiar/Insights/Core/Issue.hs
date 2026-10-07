module Test.Peculiar.Insights.Core.Issue (tests) where

import Data.Time (addUTCTime)
import Hedgehog
import Hedgehog.Gen qualified as Gen
import Hedgehog.Range qualified as Range
import Peculiar.Insights.Core.Issue
import Test.Peculiar.Insights.Core.Gen qualified as Gen

tests :: Group
tests =
  Group
    "Issue"
    [ ("a sighting never moves last seen backwards", lastSeenMonotone)
    , ("a resolved issue seen on a newer build regresses", regression)
    , ("a resolved issue seen on the resolved build stays resolved", noRegressionOnOldBuild)
    , ("an ignored issue stays ignored", ignoredStays)
    ]

issue :: Gen Issue
issue = do
  firstSeen <- Gen.utcTime
  lastSeen <- addUTCTime . fromInteger <$> Gen.integral (Range.linear 0 86400) <*> pure firstSeen
  firstBuild <- Gen.identifier
  lastBuild <- Gen.identifier
  state <- Gen.enumBounded
  resolvedBuild <- Gen.maybe Gen.identifier
  regressedAt <- Gen.maybe Gen.utcTime
  pure Issue{state, firstSeen, lastSeen, firstBuild, lastBuild = max firstBuild lastBuild, resolvedBuild, regressedAt}

lastSeenMonotone :: Property
lastSeenMonotone = property do
  existing <- forAll issue
  sighting <- forAll (Sighting <$> Gen.utcTime <*> Gen.identifier)
  let updated = observe sighting existing
  assert (updated.lastSeen >= existing.lastSeen)
  assert (updated.lastSeen >= sighting.at)

regression :: Property
regression = property do
  existing <- forAll issue
  build <- forAll Gen.identifier
  at <- forAll Gen.utcTime
  let resolved = existing{state = Resolved, resolvedBuild = Just build}
      newer = build <> "z"
      updated = observe Sighting{at, build = newer} resolved
  updated.state === Open
  updated.regressedAt === Just at

noRegressionOnOldBuild :: Property
noRegressionOnOldBuild = property do
  existing <- forAll issue
  build <- forAll Gen.identifier
  at <- forAll Gen.utcTime
  let resolved = existing{state = Resolved, resolvedBuild = Just build}
      updated = observe Sighting{at, build} resolved
  updated.state === Resolved

ignoredStays :: Property
ignoredStays = property do
  existing <- forAll issue
  sighting <- forAll (Sighting <$> Gen.utcTime <*> Gen.identifier)
  (observe sighting existing{state = Ignored}).state === Ignored
