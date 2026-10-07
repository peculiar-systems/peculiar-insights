module Peculiar.Insights.Core.Ingest
  ( Rejection (..)
  , Outcome (..)
  , Policy (..)
  , plan
  , describeRejection
  ) where

import Data.Bifunctor (first)

import Data.Text qualified as T
import Data.Time (UTCTime)
import Peculiar.Insights.Core.Consent (Purpose, Snapshot, permits, purposeName)
import Peculiar.Insights.Core.Item (Item, ItemId, itemId, itemPurpose, itemTime, setTime)
import Peculiar.Insights.Core.Time (Age (..), Skew, Window, correct, withinWindow)
import Peculiar.Insights.Core.Validate (Invalid, Limits, describeInvalid, validate)

data Rejection
  = Invalid Invalid
  | NotConsented Purpose
  | OutOfWindow Age
  deriving stock (Eq, Show)

data Outcome
  = Accepted Item
  | Rejected ItemId Rejection
  deriving stock (Eq, Show)

data Policy = Policy
  { limits :: Limits
  , window :: Window
  , consent :: Snapshot
  , skew :: Skew
  , now :: UTCTime
  }
  deriving stock (Eq, Show)

plan :: Policy -> Item -> Outcome
plan policy item = either (Rejected (itemId item)) Accepted do
  valid <- first Invalid (validate policy.limits item)
  let purpose = itemPurpose valid
  if permits policy.consent purpose then Right () else Left (NotConsented purpose)
  let corrected = correct policy.skew (itemTime valid)
  first OutOfWindow (withinWindow policy.window policy.now corrected)
  pure (setTime corrected valid)

describeRejection :: Rejection -> T.Text
describeRejection = \case
  Invalid invalid -> describeInvalid invalid
  NotConsented purpose -> "the " <> purposeName purpose <> " purpose is not granted"
  OutOfWindow Stale -> "the item is older than the accepted window"
  OutOfWindow Future -> "the item is timestamped in the future"
