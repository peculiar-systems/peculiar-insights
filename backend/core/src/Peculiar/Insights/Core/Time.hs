module Peculiar.Insights.Core.Time
  ( Skew (..)
  , skewBetween
  , correct
  , Window (..)
  , defaultWindow
  , Age (..)
  , withinWindow
  ) where

import Data.Time (NominalDiffTime, UTCTime, addUTCTime, diffUTCTime, nominalDay)

newtype Skew = Skew NominalDiffTime
  deriving stock (Eq, Show)

skewBetween :: UTCTime -> UTCTime -> Skew
skewBetween receivedAt sentAt = Skew (diffUTCTime receivedAt sentAt)

correct :: Skew -> UTCTime -> UTCTime
correct (Skew offset) = addUTCTime offset

data Window = Window
  { past :: NominalDiffTime
  , future :: NominalDiffTime
  }
  deriving stock (Eq, Show)

defaultWindow :: Window
defaultWindow = Window{past = 90 * nominalDay, future = 300}

data Age = Stale | Future
  deriving stock (Eq, Show, Enum, Bounded)

withinWindow :: Window -> UTCTime -> UTCTime -> Either Age ()
withinWindow window now at
  | at < addUTCTime (negate window.past) now = Left Stale
  | at > addUTCTime window.future now = Left Future
  | otherwise = Right ()
