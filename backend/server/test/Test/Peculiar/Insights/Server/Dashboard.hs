module Test.Peculiar.Insights.Server.Dashboard
  ( Dashboard (..)
  , Templating (..)
  , Variable (..)
  , Kind (..)
  , Current (..)
  , Panel (..)
  , Target (..)
  , Bindings (..)
  , Binding (..)
  , TimeRange (..)
  , Unresolved (..)
  , PanelQuery (..)
  , panelQueries
  , interpolate
  , describeUnresolved
  ) where

import Data.Aeson (FromJSON)
import Data.Char (isAlphaNum, isLetter)
import Data.Foldable (fold)
import Data.Map.Strict qualified as Map
import Data.Text qualified as T
import Data.Text.Read (decimal)
import Data.Time (UTCTime)
import Data.Time.Format.ISO8601 (iso8601Show)
import Deriving.Aeson (CamelToSnake, ConstructorTagModifier, CustomJSON (..), FieldLabelModifier, Rename)
import GHC.Generics (Generic, Generically (..))

data Dashboard = Dashboard
  { title :: T.Text
  , templating :: Templating
  , panels :: [Panel]
  }
  deriving stock (Eq, Show, Generic)
  deriving (FromJSON) via Generically Dashboard

newtype Templating = Templating {list :: [Variable]}
  deriving stock (Eq, Show, Generic)
  deriving (FromJSON) via Generically Templating

data Kind = Query | Textbox | Custom
  deriving stock (Eq, Show, Generic)
  deriving (FromJSON) via CustomJSON '[ConstructorTagModifier '[CamelToSnake]] Kind

data Variable = Variable
  { name :: T.Text
  , kind :: Kind
  , query :: T.Text
  , current :: Maybe Current
  , multi :: Maybe Bool
  , includeAll :: Maybe Bool
  }
  deriving stock (Eq, Show, Generic)
  deriving (FromJSON) via CustomJSON '[FieldLabelModifier '[Rename "kind" "type"]] Variable

newtype Current = Current {value :: Maybe T.Text}
  deriving stock (Eq, Show, Generic)
  deriving (FromJSON) via Generically Current

data Panel = Panel
  { id :: Int
  , title :: T.Text
  , targets :: Maybe [Target]
  , panels :: Maybe [Panel]
  }
  deriving stock (Eq, Show, Generic)
  deriving (FromJSON) via Generically Panel

data Target = Target
  { refId :: T.Text
  , rawSql :: T.Text
  }
  deriving stock (Eq, Show, Generic)
  deriving (FromJSON) via Generically Target

data PanelQuery = PanelQuery
  { panel :: Panel
  , target :: Target
  }
  deriving stock (Eq, Show)

panelQueries :: Dashboard -> [PanelQuery]
panelQueries dashboard = concatMap within dashboard.panels
 where
  within panel = [PanelQuery{panel, target} | target <- fold panel.targets] <> foldMap (concatMap within) panel.panels

data TimeRange = TimeRange
  { from :: UTCTime
  , to :: UTCTime
  }
  deriving stock (Eq, Show)

data Binding = Binding
  { values :: [T.Text]
  , multiple :: Bool
  }
  deriving stock (Eq, Show)

data Bindings = Bindings
  { range :: TimeRange
  , intervalSeconds :: Int
  , variables :: Map.Map T.Text Binding
  }
  deriving stock (Eq, Show)

data Unresolved
  = UnknownVariable T.Text
  | UnknownFormat T.Text
  | UnknownMacro T.Text
  | MalformedMacro T.Text
  | UnknownInterval T.Text
  deriving stock (Eq, Show)

describeUnresolved :: Unresolved -> T.Text
describeUnresolved = \case
  UnknownVariable name -> "no variable named " <> name
  UnknownFormat format -> "no variable format named " <> format
  UnknownMacro called -> "no macro named $" <> called
  MalformedMacro called -> "a malformed use of $" <> called
  UnknownInterval interval -> "an interval that is not a duration: " <> interval

interpolate :: Bindings -> T.Text -> Either Unresolved T.Text
interpolate bindings text = case T.breakOn "$" text of
  (before, rest)
    | T.null rest -> Right before
    | otherwise -> (before <>) <$> afterDollar bindings (T.drop 1 rest)

afterDollar :: Bindings -> T.Text -> Either Unresolved T.Text
afterDollar bindings rest
  | Just braced <- T.stripPrefix "{" rest = case T.breakOn "}" braced of
      (_, after) | T.null after -> Left (MalformedMacro ("{" <> braced))
      (inner, after) -> do
        let (name, format) = T.breakOn ":" inner
        rendered <- variable bindings name (T.drop 1 format)
        (rendered <>) <$> interpolate bindings (T.drop 1 after)
  | Just global <- T.stripPrefix "__" rest =
      let (name, after) = T.span isIdentifier global
       in macro bindings name after
  | Just (first, _) <- T.uncons rest
  , isLetter first =
      let (name, after) = T.span isIdentifier rest
       in (<>) <$> variable bindings name "" <*> interpolate bindings after
  | otherwise = ("$" <>) <$> interpolate bindings rest

isIdentifier :: Char -> Bool
isIdentifier c = isAlphaNum c || c == '_'

variable :: Bindings -> T.Text -> T.Text -> Either Unresolved T.Text
variable bindings name format = case Map.lookup name bindings.variables of
  Nothing -> Left (UnknownVariable name)
  Just binding -> case format of
    "" | binding.multiple -> Right (T.intercalate "," (fmap quoted binding.values))
    "" -> Right (T.intercalate "," (fmap escaped binding.values))
    "sqlstring" -> Right (T.intercalate "," (fmap quoted binding.values))
    "raw" -> Right (T.intercalate "," binding.values)
    other -> Left (UnknownFormat other)

escaped :: T.Text -> T.Text
escaped = T.replace "'" "''"

quoted :: T.Text -> T.Text
quoted value = "'" <> escaped value <> "'"

macro :: Bindings -> T.Text -> T.Text -> Either Unresolved T.Text
macro bindings name after = case name of
  "interval" -> ((T.pack (show bindings.intervalSeconds) <> "s") <>) <$> interpolate bindings after
  "timeFilter" -> applied \case
    [column] -> Right (column <> " BETWEEN " <> moment bindings.range.from <> " AND " <> moment bindings.range.to)
    _ -> Left (MalformedMacro name)
  "timeFrom" -> applied \case
    [""] -> Right (moment bindings.range.from)
    _ -> Left (MalformedMacro name)
  "timeTo" -> applied \case
    [""] -> Right (moment bindings.range.to)
    _ -> Left (MalformedMacro name)
  "timeGroupAlias" -> applied \case
    [column, interval] -> do
      seconds <- maybe (Left (UnknownInterval interval)) Right (duration interval)
      let step = T.pack (show seconds)
      Right ("floor(extract(epoch from " <> column <> ")/" <> step <> ")*" <> step <> " AS \"time\"")
    _ -> Left (MalformedMacro name)
  _ -> Left (UnknownMacro name)
 where
  applied expand = case parenthesised after of
    Nothing -> Left (MalformedMacro name)
    Just (inside, rest) -> do
      arguments <- interpolate bindings inside
      expanded <- expand (fmap T.strip (splitTopLevel arguments))
      (expanded <>) <$> interpolate bindings rest

moment :: UTCTime -> T.Text
moment at = "'" <> T.pack (iso8601Show at) <> "'"

parenthesised :: T.Text -> Maybe (T.Text, T.Text)
parenthesised text = T.stripPrefix "(" text >>= closing (0 :: Int) ""
 where
  closing depth seen rest = case T.uncons rest of
    Nothing -> Nothing
    Just (')', after) | depth == 0 -> Just (seen, after)
    Just (c, after) -> closing (depth + nesting c) (T.snoc seen c) after

splitTopLevel :: T.Text -> [T.Text]
splitTopLevel = go (0 :: Int) ""
 where
  go depth seen rest = case T.uncons rest of
    Nothing -> [seen]
    Just (',', after) | depth == 0 -> seen : go depth "" after
    Just (c, after) -> go (depth + nesting c) (T.snoc seen c) after

nesting :: Char -> Int
nesting = \case
  '(' -> 1
  ')' -> -1
  _ -> 0

duration :: T.Text -> Maybe Int
duration text = case decimal text of
  Right (amount, unit) -> (amount *) <$> lookup unit units
  Left _ -> Nothing
 where
  units = [("s", 1), ("m", 60), ("h", 3600), ("d", 86400)]
