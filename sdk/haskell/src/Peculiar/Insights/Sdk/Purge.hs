module Peculiar.Insights.Sdk.Purge
  ( Purge (..)
  , Reason (..)
  , covers
  , reasonFor
  ) where

import Data.Maybe (isNothing)
import Data.Time (UTCTime)
import Peculiar.Insights.Sdk.Encode (Described (..))
import Peculiar.Insights.Sdk.Types (DeviceId (..), Purpose, UserId (..))

data Reason
  = ConsentWithdrawn
  | ErasureAsked
  deriving stock (Eq, Show, Enum, Bounded)

data Purge = Purge
  { device :: DeviceId
  , user :: Maybe UserId
  , purposes :: [Purpose]
  , at :: UTCTime
  , reason :: Reason
  }
  deriving stock (Eq, Show)

covers :: DeviceId -> Purge -> Described -> Bool
covers process purge item =
  item.purpose `elem` purge.purposes
    && item.time <= purge.at
    && (sameUser || sameDevice && isNothing item.user && not shared)
 where
  sameUser = any (\(UserId wanted) -> item.user == Just wanted) purge.user
  sameDevice = (\(DeviceId wanted) -> item.device == wanted) purge.device
  shared = purge.device == process && not (null purge.user)

reasonFor :: DeviceId -> [Purge] -> Described -> Maybe Purge
reasonFor process purges item = case filter (\purge -> covers process purge item) purges of
  purge : _ -> Just purge
  [] -> Nothing
