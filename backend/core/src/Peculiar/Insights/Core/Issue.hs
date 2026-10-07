module Peculiar.Insights.Core.Issue
  ( IssueState (..)
  , Issue (..)
  , Sighting (..)
  , observe
  , stateName
  , stateFromName
  ) where

import Data.Text qualified as T
import Data.Time (UTCTime)
import GHC.Generics (Generic)
import Optics.Core ((&), (.~))
import Peculiar.Insights.Core.Enum (enumerate)

data IssueState = Open | Resolved | Ignored
  deriving stock (Eq, Show, Enum, Bounded)

stateName :: IssueState -> T.Text
stateName = \case
  Open -> "open"
  Resolved -> "resolved"
  Ignored -> "ignored"

stateFromName :: T.Text -> Maybe IssueState
stateFromName name = lookup name [(stateName state, state) | state <- enumerate]

data Issue = Issue
  { state :: IssueState
  , firstSeen :: UTCTime
  , lastSeen :: UTCTime
  , firstBuild :: T.Text
  , lastBuild :: T.Text
  , resolvedBuild :: Maybe T.Text
  , regressedAt :: Maybe UTCTime
  }
  deriving stock (Eq, Show, Generic)

data Sighting = Sighting
  { at :: UTCTime
  , build :: T.Text
  }
  deriving stock (Eq, Show)

observe :: Sighting -> Issue -> Issue
observe sighting issue =
  seen
    & #state
    .~ (if regressed then Open else issue.state)
    & #regressedAt
    .~ (if regressed then Just sighting.at else issue.regressedAt)
 where
  seen =
    issue
      & #lastSeen
      .~ max issue.lastSeen sighting.at
      & #lastBuild
      .~ max issue.lastBuild sighting.build
  regressed = issue.state == Resolved && all (< sighting.build) issue.resolvedBuild
