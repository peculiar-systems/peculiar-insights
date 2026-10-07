module Test.Peculiar.Insights.Core.Profile (tests) where

import Data.Aeson qualified as Aeson
import Data.Map.Strict qualified as Map
import Hedgehog
import Hedgehog.Gen qualified as Gen
import Hedgehog.Range qualified as Range
import Peculiar.Insights.Core.Item (ProfileOperation (..))
import Peculiar.Insights.Core.Profile
import Peculiar.Insights.Core.Value (toAeson)
import Test.Peculiar.Insights.Core.Gen qualified as Gen

tests :: Group
tests =
  Group
    "Profile"
    [ ("set overwrites", setOverwrites)
    , ("set once keeps the first value", setOnceKeeps)
    , ("unset removes", unsetRemoves)
    , ("increments add up", incrementsAdd)
    ]

setOverwrites :: Property
setOverwrites = property do
  key <- forAll Gen.identifier
  first <- forAll Gen.value
  second <- forAll Gen.value
  Map.lookup key (apply Map.empty [Set key first, Set key second]) === Just (toAeson second)

setOnceKeeps :: Property
setOnceKeeps = property do
  key <- forAll Gen.identifier
  first <- forAll Gen.value
  second <- forAll Gen.value
  Map.lookup key (apply Map.empty [SetOnce key first, SetOnce key second]) === Just (toAeson first)

unsetRemoves :: Property
unsetRemoves = property do
  key <- forAll Gen.identifier
  value <- forAll Gen.value
  Map.lookup key (apply Map.empty [Set key value, Unset key]) === Nothing

incrementsAdd :: Property
incrementsAdd = property do
  key <- forAll Gen.identifier
  steps <- forAll (Gen.list (Range.linear 0 10) (Gen.int (Range.linear (-100) 100)))
  let total = fromIntegral (sum steps) :: Double
  Map.lookup key (apply Map.empty (fmap (Increment key . fromIntegral) steps)) === (if null steps then Nothing else Just (Aeson.toJSON total))
