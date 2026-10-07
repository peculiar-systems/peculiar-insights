module Peculiar.Insights.Core.Value
  ( Value (..)
  , toAeson
  , depth
  , longestString
  ) where

import Data.Aeson qualified as Aeson
import Data.Int (Int64)
import Data.Map.Strict qualified as Map
import Data.Text qualified as T
import Data.Time (UTCTime)
import Data.Time.Format.ISO8601 (iso8601Show)

data Value
  = VString T.Text
  | VInt Int64
  | VDouble Double
  | VBool Bool
  | VTime UTCTime
  | VList [Value]
  | VMap (Map.Map T.Text Value)
  deriving stock (Eq, Show)

toAeson :: Value -> Aeson.Value
toAeson = \case
  VString text -> Aeson.toJSON text
  VInt n -> Aeson.toJSON n
  VDouble d -> Aeson.toJSON d
  VBool b -> Aeson.Bool b
  VTime t -> Aeson.toJSON (T.pack (iso8601Show t))
  VList values -> Aeson.toJSON (fmap toAeson values)
  VMap entries -> Aeson.toJSON (fmap toAeson entries)

depth :: Value -> Int
depth = \case
  VList values -> 1 + deepest values
  VMap entries -> 1 + deepest (Map.elems entries)
  _ -> 0
 where
  deepest = foldl' (\acc value -> max acc (depth value)) 0

longestString :: Value -> Int
longestString = \case
  VString text -> T.length text
  VList values -> longest values
  VMap entries -> foldl' max (longest (Map.elems entries)) (fmap T.length (Map.keys entries))
  _ -> 0
 where
  longest = foldl' (\acc value -> max acc (longestString value)) 0
