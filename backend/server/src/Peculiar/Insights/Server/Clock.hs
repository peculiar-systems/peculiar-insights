module Peculiar.Insights.Server.Clock
  ( Clock (..)
  , systemClock
  , fixedClock
  ) where

import Data.Time (UTCTime, getCurrentTime)

newtype Clock = Clock {now :: IO UTCTime}

systemClock :: Clock
systemClock = Clock{now = getCurrentTime}

fixedClock :: UTCTime -> Clock
fixedClock at = Clock{now = pure at}
