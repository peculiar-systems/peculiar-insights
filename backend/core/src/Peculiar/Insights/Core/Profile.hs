module Peculiar.Insights.Core.Profile
  ( Properties
  , apply
  ) where

import Data.Aeson qualified as Aeson
import Data.Map.Strict qualified as Map
import Data.Scientific (toRealFloat)
import Data.Text qualified as T
import Peculiar.Insights.Core.Item (ProfileOperation (..))
import Peculiar.Insights.Core.Value (toAeson)

type Properties = Map.Map T.Text Aeson.Value

apply :: Properties -> [ProfileOperation] -> Properties
apply = foldl' step
 where
  step properties = \case
    Set key value -> Map.insert key (toAeson value) properties
    SetOnce key value -> Map.insertWith (\_ existing -> existing) key (toAeson value) properties
    Unset key -> Map.delete key properties
    Increment key by -> Map.alter (Just . Aeson.toJSON . (+ by) . numberOf) key properties

numberOf :: Maybe Aeson.Value -> Double
numberOf = \case
  Just (Aeson.Number n) -> toRealFloat n
  _ -> 0
