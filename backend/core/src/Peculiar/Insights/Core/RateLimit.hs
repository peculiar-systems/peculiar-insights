module Peculiar.Insights.Core.RateLimit
  ( Bucket (..)
  , Verdict (..)
  , full
  , spend
  , idle
  , pushbackMillis
  ) where

import Data.Time (NominalDiffTime, UTCTime, diffUTCTime)
import Peculiar.Insights.Core.Config (Rate (..))

data Bucket = Bucket
  { tokens :: Double
  , updated :: UTCTime
  }
  deriving stock (Eq, Show)

data Verdict
  = Allowed
  | Limited NominalDiffTime
  deriving stock (Eq, Show)

capacity :: Rate -> Double
capacity rate = fromIntegral (max 1 rate.burst)

perSecond :: Rate -> Double
perSecond rate = fromIntegral (max 1 rate.perMinute) / 60

full :: Rate -> UTCTime -> Bucket
full rate now = Bucket{tokens = capacity rate, updated = now}

refilled :: Rate -> UTCTime -> Bucket -> Bucket
refilled rate now bucket =
  Bucket
    { tokens = min (capacity rate) (bucket.tokens + elapsed * perSecond rate)
    , updated = max now bucket.updated
    }
 where
  elapsed = max 0 (realToFrac (diffUTCTime now bucket.updated))

spend :: Rate -> UTCTime -> Int -> Bucket -> (Verdict, Bucket)
spend rate now cost bucket
  | current.tokens >= wanted = (Allowed, current{tokens = current.tokens - wanted})
  | otherwise = (Limited (realToFrac ((wanted - current.tokens) / perSecond rate)), current)
 where
  current = refilled rate now bucket
  wanted = min (capacity rate) (fromIntegral (max 1 cost))

idle :: Rate -> UTCTime -> Bucket -> Bool
idle rate now bucket = (refilled rate now bucket).tokens >= capacity rate

pushbackMillis :: NominalDiffTime -> Int
pushbackMillis wait = max 250 (min 300_000 (ceiling (realToFrac wait * 1000 :: Double)))
