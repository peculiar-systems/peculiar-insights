module Fixtures
  ( consentGen
  , everything
  , device
  ) where

import Data.Text qualified as T
import Hedgehog (Gen)
import Hedgehog.Gen qualified as Gen
import Peculiar.Insights.Sdk

consentGen :: Gen Consent
consentGen = Consent <$> Gen.maybe grant <*> Gen.maybe grant
 where
  grant = Gen.choice [Granted <$> version, Withdrawn <$> version]
  version = Gen.element (["v1", "v2"] :: [T.Text])

everything :: ConsentPolicy
everything = Assumed Bases{analytics = Just (Basis "test"), diagnostics = Just (Basis "test")}

device :: Subject
device = Subject{device = DeviceId "d", user = Just (UserId "u"), session = SessionId "s"}
