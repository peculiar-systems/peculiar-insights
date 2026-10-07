module Test.Peculiar.Insights.Core.Fingerprint (tests) where

import Data.Text qualified as T
import Hedgehog
import Hedgehog.Gen qualified as Gen
import Hedgehog.Range qualified as Range
import Peculiar.Insights.Core.Fingerprint
import Peculiar.Insights.Core.Item (Frame (..))
import Test.Peculiar.Insights.Core.Gen qualified as Gen

tests :: Group
tests =
  Group
    "Fingerprint"
    [ ("line numbers do not change the fingerprint", lineNumbersIgnored)
    , ("the message does not matter when frames exist", messageIgnoredWithFrames)
    , ("numbers in a message do not change the fingerprint", numbersNormalized)
    , ("a different exception type changes the fingerprint", typeMatters)
    ]

lineNumbersIgnored :: Property
lineNumbersIgnored = property do
  exceptionType <- forAll Gen.identifier
  frames <- forAll (Gen.list (Range.linear 1 8) Gen.frame)
  lines' <- forAll (Gen.list (Range.singleton (length frames)) (Gen.word32 (Range.linear 0 99999)))
  let moved = zipWith (\frame line -> frame{line}) frames lines'
  fingerprint exceptionType "a" frames === fingerprint exceptionType "b" moved

messageIgnoredWithFrames :: Property
messageIgnoredWithFrames = property do
  exceptionType <- forAll Gen.identifier
  frames <- forAll (Gen.list (Range.linear 1 8) Gen.frame)
  first <- forAll (Gen.text (Range.linear 0 50) Gen.unicode)
  second <- forAll (Gen.text (Range.linear 0 50) Gen.unicode)
  fingerprint exceptionType first frames === fingerprint exceptionType second frames

numbersNormalized :: Property
numbersNormalized = property do
  exceptionType <- forAll Gen.identifier
  a <- forAll (Gen.int (Range.linear 0 100000))
  b <- forAll (Gen.int (Range.linear 0 100000))
  let message n = "index " <> T.pack (show n) <> " out of range"
  fingerprint exceptionType (message a) [] === fingerprint exceptionType (message b) []

typeMatters :: Property
typeMatters = property do
  first <- forAll Gen.identifier
  second <- forAll (Gen.filter (/= first) Gen.identifier)
  frames <- forAll (Gen.list (Range.linear 0 4) Gen.frame)
  fingerprint first "" frames /== fingerprint second "" frames
