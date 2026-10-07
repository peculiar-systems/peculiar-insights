module Peculiar.Insights.Sdk.Testing
  ( Recorded (..)
  , recording
  , recordingAt
  ) where

import Control.Monad (void)
import Data.IORef (newIORef, readIORef)
import Data.Time (UTCTime, getCurrentTime)
import GHC.IORef (atomicModifyIORef'_)
import Peculiar.Insights.Sdk.Config (ConsentPolicy, Diagnostic, policyConsent)
import Peculiar.Insights.Sdk.Core (Sink (..))
import Peculiar.Insights.Sdk.Insights (Insights (..))
import Peculiar.Insights.Sdk.Tracker (mkTracker)
import Peculiar.Insights.Sdk.Types

data Recorded = Recorded
  { consent :: Consent
  , item :: Item
  }
  deriving stock (Eq, Show)

recording :: ConsentPolicy -> Subject -> IO (Insights, IO [Recorded], IO [Diagnostic])
recording = recordingAt getCurrentTime

recordingAt :: IO UTCTime -> ConsentPolicy -> Subject -> IO (Insights, IO [Recorded], IO [Diagnostic])
recordingAt now policy subject = do
  items <- newIORef []
  logs <- newIORef []
  diagnostics <- newIORef []
  let sink =
        Sink
          { emit = \consent item -> void (atomicModifyIORef'_ items (Recorded{consent, item} :))
          , note = \line -> void (atomicModifyIORef'_ logs (line :))
          , recent = reverse <$> readIORef logs
          , now
          , diagnose = \entry -> void (atomicModifyIORef'_ diagnostics (entry :))
          }
      insights =
        Insights
          { tracker = mkTracker sink subject (policyConsent policy)
          , subject = mkTracker sink
          , flush = pure ()
          , recordConsent = \_ _ _ _ -> pure (Right ())
          , erase = \_ _ -> pure (Right ())
          }
  pure (insights, reverse <$> readIORef items, reverse <$> readIORef diagnostics)
