module Peculiar.Insights.Server.Projects
  ( Registered (..)
  , Projects (..)
  , mkProjects
  ) where

import Data.ByteString qualified as BS
import Data.Int (Int32)
import Data.Map.Strict qualified as Map
import Peculiar.Insights.Core.Config (Project)

data Registered = Registered
  { id :: Int32
  , project :: Project
  }
  deriving stock (Eq, Show)

newtype Projects = Projects {byKey :: BS.ByteString -> Maybe Registered}

mkProjects :: [(BS.ByteString, Registered)] -> Projects
mkProjects pairs = Projects{byKey = (`Map.lookup` table)}
 where
  table = Map.fromList pairs
