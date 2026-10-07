module Peculiar.Insights.Server.Limiter
  ( Limiter (..)
  , Scope (..)
  , newLimiter
  , unlimited
  ) where

import Data.IORef (atomicModifyIORef', newIORef)
import Data.Int (Int32)
import Data.Map.Strict qualified as Map
import Data.Text qualified as T
import Data.Time (UTCTime)
import Peculiar.Insights.Core.Config (Rate)
import Peculiar.Insights.Core.RateLimit (Verdict (..), full, idle, spend)

data Scope
  = OfKey Int32
  | OfPeer T.Text
  deriving stock (Eq, Ord, Show)

newtype Limiter = Limiter {admit :: Scope -> Rate -> UTCTime -> Int -> IO Verdict}

unlimited :: Limiter
unlimited = Limiter{admit = \_ _ _ _ -> pure Allowed}

crowded :: Int
crowded = 20_000

newLimiter :: IO Limiter
newLimiter = do
  buckets <- newIORef Map.empty
  pure
    Limiter
      { admit = \scope rate now cost -> atomicModifyIORef' buckets \held ->
          let (verdict, next) = spend rate now cost (Map.findWithDefault (full rate now) scope held)
              kept = if Map.size held > crowded then Map.filterWithKey (busy rate now) held else held
           in (Map.insert scope next kept, verdict)
      }
 where
  busy rate now scope bucket = case scope of
    OfKey _ -> True
    OfPeer _ -> not (idle rate now bucket)
