module Peculiar.Insights.Inventory
  ( Category (..)
  , Purpose (..)
  , Entry (..)
  , Inventory (..)
  , AccessedApi (..)
  , fromDescriptorSet
  , renderMarkdown
  , renderManifest
  , categoryTag
  , purposeTag
  ) where

import Data.Aeson (FromJSON, ToJSON)
import Data.ByteString qualified as BS
import Data.List (sortOn)
import Data.Map.Strict qualified as Map
import Data.Maybe (mapMaybe)
import Data.ProtoLens (decodeMessage)
import Data.ProtoLens.Encoding.Wire (Tag (..), TaggedValue (..), WireValue (..))
import Data.ProtoLens.Labels ()
import Data.ProtoLens.Message (unknownFields)
import Data.Text qualified as T
import Deriving.Aeson (CamelToSnake, CustomJSON (..), FieldLabelModifier)
import GHC.Generics (Generic)
import Lens.Family2 ((^.))
import Proto.Google.Protobuf.Descriptor (DescriptorProto, FieldDescriptorProto, FileDescriptorSet)

data Category
  = None
  | DeviceId
  | UserId
  | DeviceInfo
  | ProductInteraction
  | CrashData
  | OtherDiagnostic
  | UserContent
  deriving stock (Eq, Ord, Show, Enum, Bounded)

data Purpose = Analytics | Diagnostics
  deriving stock (Eq, Ord, Show, Enum, Bounded)

data Entry = Entry
  { message :: T.Text
  , field :: T.Text
  , category :: Category
  , purpose :: Maybe Purpose
  }
  deriving stock (Eq, Ord, Show)

newtype Inventory = Inventory [Entry]
  deriving stock (Eq, Show)

data AccessedApi = AccessedApi
  { apiType :: T.Text
  , reasons :: [T.Text]
  }
  deriving stock (Eq, Show, Generic)
  deriving (FromJSON, ToJSON) via CustomJSON '[FieldLabelModifier '[CamelToSnake]] AccessedApi

categoryTag :: Int
categoryTag = 50101

purposeTag :: Int
purposeTag = 50102

categoryOf :: Integer -> Maybe Category
categoryOf = \case
  1 -> Just None
  2 -> Just DeviceId
  3 -> Just UserId
  4 -> Just DeviceInfo
  5 -> Just ProductInteraction
  6 -> Just CrashData
  7 -> Just OtherDiagnostic
  8 -> Just UserContent
  _ -> Nothing

purposeOf :: Integer -> Maybe Purpose
purposeOf = \case
  1 -> Just Analytics
  2 -> Just Diagnostics
  _ -> Nothing

fromDescriptorSet :: BS.ByteString -> Either T.Text Inventory
fromDescriptorSet bytes = case decodeMessage @FileDescriptorSet bytes of
  Left failure -> Left (T.pack failure)
  Right set -> Right (Inventory (sortOn (\entry -> (entry.message, entry.field)) (concatMap fileEntries (set ^. #file))))
 where
  fileEntries file = concatMap (messageEntries (file ^. #package)) (file ^. #messageType)

messageEntries :: T.Text -> DescriptorProto -> [Entry]
messageEntries prefix descriptor =
  mapMaybe (fieldEntry qualified) (descriptor ^. #field)
    <> concatMap (messageEntries qualified) (descriptor ^. #nestedType)
 where
  qualified = if T.null prefix then descriptor ^. #name else prefix <> "." <> descriptor ^. #name

fieldEntry :: T.Text -> FieldDescriptorProto -> Maybe Entry
fieldEntry message field = do
  category <- lookup categoryTag options >>= categoryOf
  pure Entry{message, field = field ^. #name, category, purpose = lookup purposeTag options >>= purposeOf}
 where
  options = [(tag, fromIntegral value) | TaggedValue (Tag tag) (VarInt value) <- field ^. #options . unknownFields]

appleType :: Category -> Maybe T.Text
appleType = \case
  None -> Nothing
  DeviceId -> Just "NSPrivacyCollectedDataTypeDeviceID"
  UserId -> Just "NSPrivacyCollectedDataTypeUserID"
  DeviceInfo -> Nothing
  ProductInteraction -> Just "NSPrivacyCollectedDataTypeProductInteraction"
  CrashData -> Just "NSPrivacyCollectedDataTypeCrashData"
  OtherDiagnostic -> Just "NSPrivacyCollectedDataTypeOtherDiagnosticData"
  UserContent -> Just "NSPrivacyCollectedDataTypeOtherUserContent"

googleType :: Category -> T.Text
googleType = \case
  None -> "not collected as personal data"
  DeviceId -> "Device or other IDs"
  UserId -> "User IDs"
  DeviceInfo -> "not a listed data type"
  ProductInteraction -> "App interactions"
  CrashData -> "Crash logs"
  OtherDiagnostic -> "Diagnostics"
  UserContent -> "Other user-generated content"

categoryName :: Category -> T.Text
categoryName = \case
  None -> "None"
  DeviceId -> "Device ID"
  UserId -> "User ID"
  DeviceInfo -> "Device info"
  ProductInteraction -> "Product interaction"
  CrashData -> "Crash data"
  OtherDiagnostic -> "Other diagnostic data"
  UserContent -> "User content"

purposeName :: Purpose -> T.Text
purposeName = \case
  Analytics -> "analytics"
  Diagnostics -> "diagnostics"

applePurpose :: Purpose -> T.Text
applePurpose = \case
  Analytics -> "NSPrivacyCollectedDataTypePurposeAnalytics"
  Diagnostics -> "NSPrivacyCollectedDataTypePurposeAppFunctionality"

renderMarkdown :: Inventory -> T.Text
renderMarkdown (Inventory entries) =
  T.unlines
    ( [ "# Data inventory"
      , ""
      , "Generated from the field annotations in `proto/peculiar/insights/v1`. Every collected field is listed with its category, the consent purpose that gates it, and the matching App Store privacy label and Google Play data safety type. Do not edit by hand; run the inventory task."
      , ""
      ]
        <> concatMap section (enumFrom minBound)
    )
 where
  grouped = Map.fromListWith (flip (<>)) [(entry.category, [entry]) | entry <- entries]
  section category = case Map.lookup category grouped of
    Nothing -> []
    Just rows ->
      [ "## " <> categoryName category
      , ""
      , "App Store: " <> maybe "not a declared data type" (const (categoryName category)) (appleType category) <> ". Google Play: " <> googleType category <> "."
      , ""
      , "| Message | Field | Purpose |"
      , "|---|---|---|"
      ]
        <> ["| `" <> row.message <> "` | `" <> row.field <> "` | " <> maybe "" purposeName row.purpose <> " |" | row <- rows]
        <> [""]

renderManifest :: Inventory -> [AccessedApi] -> T.Text
renderManifest (Inventory entries) accessed =
  T.unlines
    ( [ "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
      , "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">"
      , "<plist version=\"1.0\">"
      , "<dict>"
      , "\t<key>NSPrivacyTracking</key>"
      , "\t<false/>"
      , "\t<key>NSPrivacyTrackingDomains</key>"
      , "\t<array/>"
      , "\t<key>NSPrivacyCollectedDataTypes</key>"
      , "\t<array>"
      ]
        <> concatMap dataType (Map.toList collected)
        <> [ "\t</array>"
           , "\t<key>NSPrivacyAccessedAPITypes</key>"
           , "\t<array>"
           ]
        <> concatMap api accessed
        <> [ "\t</array>"
           , "</dict>"
           , "</plist>"
           ]
    )
 where
  linked = any (\entry -> entry.category == UserId) entries
  collected =
    Map.fromListWith
      (<>)
      [ (apple, foldMap pure entry.purpose)
      | entry <- entries
      , Just apple <- [appleType entry.category]
      ]
  dataType (apple, purposes) =
    [ "\t\t<dict>"
    , "\t\t\t<key>NSPrivacyCollectedDataType</key>"
    , "\t\t\t<string>" <> apple <> "</string>"
    , "\t\t\t<key>NSPrivacyCollectedDataTypeLinked</key>"
    , if linked then "\t\t\t<true/>" else "\t\t\t<false/>"
    , "\t\t\t<key>NSPrivacyCollectedDataTypeTracking</key>"
    , "\t\t\t<false/>"
    , "\t\t\t<key>NSPrivacyCollectedDataTypePurposes</key>"
    , "\t\t\t<array>"
    ]
      <> ["\t\t\t\t<string>" <> applePurpose purpose <> "</string>" | purpose <- unique purposes]
      <> [ "\t\t\t</array>"
         , "\t\t</dict>"
         ]
  api entry =
    [ "\t\t<dict>"
    , "\t\t\t<key>NSPrivacyAccessedAPIType</key>"
    , "\t\t\t<string>" <> entry.apiType <> "</string>"
    , "\t\t\t<key>NSPrivacyAccessedAPITypeReasons</key>"
    , "\t\t\t<array>"
    ]
      <> ["\t\t\t\t<string>" <> reason <> "</string>" | reason <- entry.reasons]
      <> [ "\t\t\t</array>"
         , "\t\t</dict>"
         ]
  unique = Map.keys . Map.fromList . fmap (,())
