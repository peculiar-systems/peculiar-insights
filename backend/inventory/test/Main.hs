module Main (main) where

import Control.Monad (unless)
import Data.ProtoLens (defMessage, encodeMessage)
import Data.ProtoLens.Encoding.Wire (Tag (..), TaggedValue (..), WireValue (..))
import Data.ProtoLens.Labels ()
import Data.ProtoLens.Message (unknownFields)
import Data.Text qualified as T
import Hedgehog
import Lens.Family2 ((&), (.~))
import Peculiar.Insights.Inventory
import Proto.Google.Protobuf.Descriptor (FieldDescriptorProto, FileDescriptorSet)
import System.Exit (exitFailure)

main :: IO ()
main = do
  ok <- checkParallel (Group "Inventory" [("annotated fields are listed and rendered", withTests 1 golden)])
  unless ok exitFailure

annotated :: T.Text -> Int -> Maybe Int -> FieldDescriptorProto
annotated name category purpose =
  defMessage
    & #name .~ name
    & #options
      .~ ( defMessage
             & unknownFields
               .~ [TaggedValue (Tag categoryTag) (VarInt (fromIntegral category))] <> [TaggedValue (Tag purposeTag) (VarInt (fromIntegral p)) | Just p <- [purpose]]
         )

descriptorSet :: FileDescriptorSet
descriptorSet =
  defMessage
    & #file
      .~ [ defMessage
             & #package .~ "peculiar.insights.v1"
             & #messageType
               .~ [ defMessage
                      & #name .~ "Event"
                      & #field .~ [annotated "id" 1 Nothing, annotated "name" 5 (Just 1), defMessage & #name .~ "plain"]
                  , defMessage
                      & #name .~ "Subject"
                      & #field .~ [annotated "user_id" 3 (Just 1)]
                  ]
         ]

golden :: Property
golden = property do
  inventory <- evalEither (fromDescriptorSet (encodeMessage descriptorSet))
  inventory
    === Inventory
      [ Entry "peculiar.insights.v1.Event" "id" None Nothing
      , Entry "peculiar.insights.v1.Event" "name" ProductInteraction (Just Analytics)
      , Entry "peculiar.insights.v1.Subject" "user_id" UserId (Just Analytics)
      ]
  let markdown = renderMarkdown inventory
  assert (T.isInfixOf "| `peculiar.insights.v1.Event` | `name` | analytics |" markdown)
  assert (T.isInfixOf "## User ID" markdown)
  let manifest = renderManifest inventory [AccessedApi{apiType = "NSPrivacyAccessedAPICategoryUserDefaults", reasons = ["CA92.1"]}]
  assert (T.isInfixOf "<string>NSPrivacyCollectedDataTypeUserID</string>" manifest)
  assert (T.isInfixOf "<string>NSPrivacyCollectedDataTypeProductInteraction</string>" manifest)
  assert (T.isInfixOf "<string>CA92.1</string>" manifest)
  assert (T.isInfixOf "<key>NSPrivacyCollectedDataTypeLinked</key>\n\t\t\t<true/>" manifest)
