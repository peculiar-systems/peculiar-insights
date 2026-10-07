module Peculiar.Insights.Sdk.Properties
  ( Properties
  , Property
  , IsProperty (..)
  , (=:)
  , properties
  , valuesOf
  , override
  ) where

import Data.Int (Int64)
import Data.Map.Strict qualified as Map
import Data.Text qualified as T
import Data.Time (UTCTime)
import GHC.IsList (IsList (..))
import Peculiar.Insights.Sdk.Types (Value (..))

newtype Properties = Properties (Map.Map T.Text Value)
  deriving stock (Eq, Show)

instance Semigroup Properties where
  Properties later <> Properties earlier = Properties (Map.union later earlier)

instance Monoid Properties where
  mempty = Properties Map.empty

type Property = (T.Text, Value)

instance IsList Properties where
  type Item Properties = Property
  fromList = properties
  toList (Properties entries) = Map.toList entries

class IsProperty a where
  toValue :: a -> Value

instance IsProperty Value where
  toValue = id

instance IsProperty T.Text where
  toValue = VString

instance IsProperty Int where
  toValue = VInt . fromIntegral

instance IsProperty Int64 where
  toValue = VInt

instance IsProperty Integer where
  toValue = VInt . fromInteger

instance IsProperty Double where
  toValue = VDouble

instance IsProperty Bool where
  toValue = VBool

instance IsProperty UTCTime where
  toValue = VTime

instance (IsProperty a) => IsProperty [a] where
  toValue = VList . fmap toValue

instance IsProperty Properties where
  toValue = VMap . valuesOf

infixr 8 =:

(=:) :: (IsProperty a) => T.Text -> a -> Property
key =: value = (key, toValue value)

properties :: [Property] -> Properties
properties = Properties . Map.fromList

valuesOf :: Properties -> Map.Map T.Text Value
valuesOf (Properties entries) = entries

override :: Properties -> Properties -> Properties
override later earlier = later <> earlier
