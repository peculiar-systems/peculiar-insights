module Peculiar.Insights.Sdk
  ( Insights (..)
  , HasInsights (..)
  , withInsights
  , disabled
  , Config (..)
  , defaultConfig
  , Endpoint (..)
  , ConsentPolicy (..)
  , Bases (..)
  , Basis (..)
  , Diagnostic (..)
  , Rejection (..)
  , Failure (..)
  , Drop (..)
  , DropCause (..)
  , Tracker
  , People (..)
  , Span (..)
  , with
  , track
  , identify
  , people
  , recordError
  , attempt
  , boundary
  , log
  , span
  , report
  , subjectOf
  , consentOf
  , scopeOf
  , Properties
  , Property
  , IsProperty (..)
  , (=:)
  , properties
  , SdkError (..)
  , module Peculiar.Insights.Sdk.Types
  ) where

import Peculiar.Insights.Sdk.Config
import Peculiar.Insights.Sdk.Direct (SdkError (..))
import Peculiar.Insights.Sdk.Insights
import Peculiar.Insights.Sdk.Properties
import Peculiar.Insights.Sdk.Tracker
import Peculiar.Insights.Sdk.Types
import Prelude hiding (log, span)
