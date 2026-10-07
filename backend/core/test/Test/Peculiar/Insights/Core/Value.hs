module Test.Peculiar.Insights.Core.Value (tests) where

import Data.Aeson qualified as Aeson
import Data.Map.Strict qualified as Map
import Hedgehog
import Peculiar.Insights.Core.Value
import Test.Peculiar.Insights.Core.Gen qualified as Gen

tests :: Group
tests =
  Group
    "Value"
    [ ("scalars have depth zero", scalarDepth)
    , ("wrapping adds one level", wrappingDepth)
    , ("integers survive the json rendering", integerRendering)
    , ("a map renders as an object with the same keys", mapRendering)
    ]

scalarDepth :: Property
scalarDepth = property do
  value <- forAll Gen.shallowValue
  depth value === 0

wrappingDepth :: Property
wrappingDepth = property do
  value <- forAll Gen.value
  depth (VList [value]) === depth value + 1
  depth (VMap (Map.singleton "k" value)) === depth value + 1

integerRendering :: Property
integerRendering = property do
  value <- forAll Gen.value
  case value of
    VInt n -> toAeson value === Aeson.toJSON n
    _ -> success

mapRendering :: Property
mapRendering = property do
  value <- forAll Gen.value
  case toAeson (VMap (Map.singleton "key" value)) of
    Aeson.Object object -> length object === 1
    other -> annotateShow other *> failure
