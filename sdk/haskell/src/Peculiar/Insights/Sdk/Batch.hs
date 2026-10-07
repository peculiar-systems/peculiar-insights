module Peculiar.Insights.Sdk.Batch
  ( Pending (..)
  , Batch (..)
  , batches
  , Retry (..)
  , classify
  , backoff
  , pause
  ) where

import Data.ByteString qualified as BS
import Data.ByteString.Char8 qualified as BC
import Data.Map.Strict qualified as Map
import Peculiar.Insights.Sdk.Types (Consent)
import Peculiar.Rpc (Code (..))

data Pending a = Pending
  { consent :: Consent
  , payload :: a
  }
  deriving stock (Eq, Show)

data Batch a = Batch
  { consent :: Consent
  , payloads :: [a]
  }
  deriving stock (Eq, Show)

batches :: Int -> [Pending a] -> [Batch a]
batches size pending =
  concatMap (\(consent, payloads) -> [Batch consent chunk | chunk <- chunks (reverse payloads)]) (Map.toList grouped)
 where
  grouped = foldl' (\acc entry -> Map.insertWith (<>) entry.consent [entry.payload] acc) Map.empty pending
  chunks [] = []
  chunks items = let (now, later) = splitAt (max 1 size) items in now : chunks later

data Retry = RetryLater | GiveUp
  deriving stock (Eq, Show)

classify :: Code -> Retry
classify = \case
  Unavailable -> RetryLater
  Unknown -> RetryLater
  DeadlineExceeded -> RetryLater
  ResourceExhausted -> RetryLater
  _ -> GiveUp

backoff :: Int -> Int
backoff attempt = min 300_000_000 (1_000_000 * 2 ^ min 8 (max 0 attempt))

pause :: Maybe BS.ByteString -> Int -> Int
pause asked attempt = case asked >>= BC.readInt of
  Just (millis, rest) | BS.null rest, millis >= 0 -> min 300_000_000 (millis * 1000)
  _ -> backoff attempt
