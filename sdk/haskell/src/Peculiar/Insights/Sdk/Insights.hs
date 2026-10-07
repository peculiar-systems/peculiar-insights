module Peculiar.Insights.Sdk.Insights
  ( Insights (..)
  , HasInsights (..)
  , withInsights
  , disabled
  ) where

import Data.Foldable (for_)
import Data.Text qualified as T
import Data.Time (getCurrentTime)
import Data.UUID qualified as UUID
import Data.UUID.V4 (nextRandom)
import Peculiar.Insights.Sdk.Config (Bases (..), Basis (..), Config (..), ConsentPolicy (..), Diagnostic (..), Failure (..), policyConsent)
import Peculiar.Insights.Sdk.Core (Core (..), Sink (..), coreSink, flushCore, purgeCore, withCore)
import Peculiar.Insights.Sdk.Direct (SdkError (..))
import Peculiar.Insights.Sdk.Direct qualified as Direct
import Peculiar.Insights.Sdk.Purge (Purge (..), Reason (..))
import Peculiar.Insights.Sdk.Tracker (Tracker, mkTracker)
import Peculiar.Insights.Sdk.Types
import Peculiar.Rpc qualified as Rpc

data Insights = Insights
  { tracker :: Tracker
  , subject :: Subject -> Consent -> Tracker
  , flush :: IO ()
  , recordConsent :: DeviceId -> Maybe UserId -> Purpose -> Grant -> IO (Either SdkError ())
  , erase :: DeviceId -> Maybe UserId -> IO (Either SdkError ())
  }

class HasInsights env where
  getInsights :: env -> Insights

withInsights :: Config -> (Insights -> IO a) -> IO a
withInsights config use = withCore config \core -> do
  session <- SessionId . UUID.toText <$> nextRandom
  let device = DeviceId config.service
      process = Subject{device, user = Nothing, session}
      consent = policyConsent config.consent
      sink = coreSink core
      insights =
        Insights
          { tracker = mkTracker sink process consent
          , subject = mkTracker sink
          , flush = flushCore core
          , recordConsent = \subject user purpose grant -> do
              case grant of
                Granted _ -> pure ()
                Withdrawn _ -> forget core ConsentWithdrawn [purpose] subject user
              Direct.recordConsent core.remote subject user purpose grant
          , erase = \subject user -> do
              forget core ErasureAsked [Analytics, Diagnostics] subject user
              Direct.requestErasure core.remote subject user
          }
  assume core device
  use insights

forget :: Core -> Reason -> [Purpose] -> DeviceId -> Maybe UserId -> IO ()
forget core reason purposes device user = do
  at <- getCurrentTime
  purgeCore core Purge{device, user, purposes, at, reason}

assume :: Core -> DeviceId -> IO ()
assume core device = case core.config.consent of
  Provided -> pure ()
  Assumed bases ->
    for_ [(Analytics, bases.analytics), (Diagnostics, bases.diagnostics)] \(purpose, basis) ->
      for_ basis \(Basis reason) ->
        Direct.recordConsent core.remote device Nothing purpose (Granted reason) >>= \case
          Right () -> pure ()
          Left (SdkError message) ->
            core.config.onDiagnostic (TransportFailed Failure{code = Rpc.Unavailable, message = T.pack "recording assumed consent: " <> message, willRetry = False})

disabled :: Insights
disabled =
  Insights
    { tracker = mkTracker silent nobody noConsent
    , subject = mkTracker silent
    , flush = pure ()
    , recordConsent = \_ _ _ _ -> pure (Right ())
    , erase = \_ _ -> pure (Right ())
    }
 where
  silent =
    Sink
      { emit = \_ _ -> pure ()
      , note = const (pure ())
      , recent = pure []
      , now = getCurrentTime
      , diagnose = const (pure ())
      }
  nobody = Subject{device = DeviceId "", user = Nothing, session = SessionId ""}
