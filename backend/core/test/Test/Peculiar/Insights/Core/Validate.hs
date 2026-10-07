module Test.Peculiar.Insights.Core.Validate (tests) where

import Data.Map.Strict qualified as Map
import Data.Text qualified as T
import Hedgehog
import Hedgehog.Gen qualified as Gen
import Hedgehog.Range qualified as Range
import Optics.Core ((&), (.~), (?~))
import Peculiar.Insights.Core.Item
import Peculiar.Insights.Core.Validate
import Peculiar.Insights.Core.Value (Value (..))
import Test.Peculiar.Insights.Core.Gen qualified as Gen

tests :: Group
tests =
  Group
    "Validate"
    [ ("generated items are valid", generatedValid)
    , ("an empty device id is rejected", emptyDevice)
    , ("an overlong event name is rejected", longName)
    , ("nesting past the limit is rejected", tooDeep)
    , ("a crash message is truncated rather than rejected", truncatedMessage)
    , ("an overlong image identifier is rejected", longImageIdentifier)
    ]

generatedValid :: Property
generatedValid = property do
  item <- forAll Gen.item
  validate defaultLimits item === Right item

emptyDevice :: Property
emptyDevice = property do
  event <- forAll Gen.event
  validate defaultLimits (ItemEvent (event & #subject .~ (event.subject & #device .~ DeviceId ""))) === Left EmptyDevice

longName :: Property
longName = property do
  event <- forAll Gen.event
  extra <- forAll (Gen.int (Range.linear 1 100))
  let name = T.replicate (defaultLimits.maxNameLength + extra) "a"
  validate defaultLimits (ItemEvent (event & #name .~ name)) === Left NameTooLong

tooDeep :: Property
tooDeep = property do
  event <- forAll Gen.event
  let nested = nest (defaultLimits.maxDepth + 1) (VInt 1)
  validate defaultLimits (ItemEvent (event & #properties .~ Map.singleton "deep" nested)) === Left (TooDeep "deep")
 where
  nest :: Int -> Value -> Value
  nest n inner
    | n <= 0 = inner
    | otherwise = VList [nest (n - 1) inner]

truncatedMessage :: Property
truncatedMessage = property do
  crash <- forAll Gen.crashReport
  extra <- forAll (Gen.int (Range.linear 1 100))
  let message = T.replicate (defaultLimits.maxMessageLength + extra) "m"
  case validate defaultLimits (ItemCrashReport (crash & #message .~ message)) of
    Right (ItemCrashReport accepted) -> T.length accepted.message === defaultLimits.maxMessageLength
    other -> annotateShow other *> failure

longImageIdentifier :: Property
longImageIdentifier = property do
  crash <- forAll Gen.crashReport
  frame <- forAll Gen.frame
  image <- forAll Gen.image
  extra <- forAll (Gen.int (Range.linear 1 100))
  let overlong = image & #identifier .~ T.replicate (defaultLimits.maxIdentifierLength + extra) "f"
      frames = (frame & #image ?~ overlong) : crash.frames
  validate defaultLimits (ItemCrashReport (crash & #frames .~ frames)) === Left (IdentifierTooLong "image identifier")
