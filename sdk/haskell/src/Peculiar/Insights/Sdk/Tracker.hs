module Peculiar.Insights.Sdk.Tracker
  ( Tracker
  , People (..)
  , Span (..)
  , mkTracker
  , subjectOf
  , consentOf
  , scopeOf
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
  ) where

import Control.Exception (Exception (..), SomeException (..), throwIO, try)

import Data.Map.Strict qualified as Map
import Data.Text qualified as T
import Data.Time (diffUTCTime)
import Data.Typeable (typeOf)
import GHC.Stack (CallStack, HasCallStack, SrcLoc (..), callStack, getCallStack)
import Peculiar.Insights.Sdk.Config (Diagnostic (..), Drop (..), DropCause (..))
import Peculiar.Insights.Sdk.Core (Sink (..))
import Peculiar.Insights.Sdk.Properties (Properties, Property, override, properties, valuesOf, (=:))
import Peculiar.Insights.Sdk.Types
import Prelude hiding (log, span)

data Tracker = Tracker
  { sink :: Sink
  , subject :: Subject
  , consent :: Consent
  , scope :: Properties
  }

mkTracker :: Sink -> Subject -> Consent -> Tracker
mkTracker sink subject consent = Tracker{sink, subject, consent, scope = mempty}

subjectOf :: Tracker -> Subject
subjectOf tracker = tracker.subject

consentOf :: Tracker -> Consent
consentOf tracker = tracker.consent

scopeOf :: Tracker -> Properties
scopeOf tracker = tracker.scope

with :: [Property] -> Tracker -> Tracker
with added tracker = tracker{scope = override (properties added) tracker.scope}

emit :: Tracker -> Item -> IO ()
emit tracker = tracker.sink.emit tracker.consent

track :: Tracker -> T.Text -> [Property] -> IO ()
track tracker name given = emit tracker (Track tracker.subject name (valuesOf (override (properties given) tracker.scope)))

identify :: Tracker -> UserId -> IO ()
identify tracker user = emit tracker (Identify tracker.subject.device user)

data People = People
  { set :: [Property] -> IO ()
  , setOnce :: [Property] -> IO ()
  , unset :: [T.Text] -> IO ()
  }

people :: Tracker -> People
people tracker =
  People
    { set = apply . fmap (uncurry Set) . Map.toList . valuesOf . properties
    , setOnce = apply . fmap (uncurry SetOnce) . Map.toList . valuesOf . properties
    , unset = apply . fmap Unset
    }
 where
  apply operations = case tracker.subject.user of
    Just user -> emit tracker (Profile tracker.subject.device user operations)
    Nothing -> tracker.sink.diagnose (Dropped Drop{count = 1, cause = NoUser})

recordError :: Tracker -> ErrorReport -> IO ()
recordError tracker given = do
  logs <- tracker.sink.recent
  emit tracker (Crash tracker.subject given{customKeys = Map.union given.customKeys (valuesOf tracker.scope), logs})

report :: (HasCallStack) => SomeException -> ErrorReport
report (SomeException inner) =
  ErrorReport
    { exceptionType = T.pack (show (typeOf inner))
    , message = T.pack (displayException inner)
    , frames = framesOf callStack
    , rawStackTrace = T.pack (show (getCallStack callStack))
    , fatal = False
    , thread = "main"
    , customKeys = Map.empty
    , logs = []
    }

framesOf :: CallStack -> [Frame]
framesOf stack =
  [ Frame
      { moduleName = T.pack location.srcLocModule
      , function = T.pack function
      , file = T.pack location.srcLocFile
      , line = fromIntegral location.srcLocStartLine
      , column = fromIntegral location.srcLocStartCol
      , inApp = True
      }
  | (function, location) <- getCallStack stack
  ]

attempt :: (HasCallStack) => Tracker -> IO a -> IO a
attempt tracker action =
  try @SomeException action >>= \case
    Right result -> pure result
    Left failure -> recordError tracker (report failure) *> throwIO failure

boundary :: (HasCallStack) => Tracker -> IO () -> IO ()
boundary tracker action =
  try @SomeException action >>= \case
    Right () -> pure ()
    Left failure -> recordError tracker (report failure)

log :: Tracker -> LogLevel -> T.Text -> IO ()
log tracker level message = do
  time <- tracker.sink.now
  tracker.sink.note LogLine{time, level, message}

newtype Span = Span {end :: [Property] -> IO ()}

span :: Tracker -> T.Text -> IO Span
span tracker name = do
  started <- tracker.sink.now
  pure
    Span
      { end = \given -> do
          finished <- tracker.sink.now
          let millis = round (diffUTCTime finished started * 1000) :: Int
          track tracker name (given <> [durationKey =: millis | durationKey `notElem` fmap fst given])
      }
 where
  durationKey = "duration_ms"
