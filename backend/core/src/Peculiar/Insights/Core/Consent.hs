module Peculiar.Insights.Core.Consent
  ( Purpose (..)
  , ConsentState (..)
  , PolicyVersion (..)
  , PurposeState (..)
  , Snapshot (..)
  , permits
  , purposeName
  ) where

import Data.Map.Strict qualified as Map
import Data.Text qualified as T

data Purpose = Analytics | Diagnostics
  deriving stock (Eq, Ord, Show, Enum, Bounded)

data ConsentState = Granted | Withdrawn
  deriving stock (Eq, Ord, Show, Enum, Bounded)

newtype PolicyVersion = PolicyVersion T.Text
  deriving stock (Eq, Ord, Show)

data PurposeState = PurposeState
  { state :: ConsentState
  , policyVersion :: PolicyVersion
  }
  deriving stock (Eq, Show)

newtype Snapshot = Snapshot (Map.Map Purpose PurposeState)
  deriving stock (Eq, Show)

permits :: Snapshot -> Purpose -> Bool
permits (Snapshot purposes) purpose = case Map.lookup purpose purposes of
  Just PurposeState{state = Granted} -> True
  _ -> False

purposeName :: Purpose -> T.Text
purposeName = \case
  Analytics -> "analytics"
  Diagnostics -> "diagnostics"
