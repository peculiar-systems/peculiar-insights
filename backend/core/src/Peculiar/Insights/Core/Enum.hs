module Peculiar.Insights.Core.Enum
  ( enumerate
  ) where

enumerate :: (Enum a, Bounded a) => [a]
enumerate = enumFrom minBound
