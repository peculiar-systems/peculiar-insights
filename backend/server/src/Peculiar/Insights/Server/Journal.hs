module Peculiar.Insights.Server.Journal
  ( Journal (..)
  , stdoutJournal
  , silentJournal
  ) where

import Control.Concurrent.MVar (newMVar, withMVar)
import Data.Aeson (Value, encode, object, (.=))
import Data.ByteString.Lazy.Char8 qualified as LBC
import Data.Text qualified as T
import Data.Time (getCurrentTime)
import System.IO (hFlush, stdout)

newtype Journal = Journal {write :: T.Text -> Value -> IO ()}

stdoutJournal :: IO Journal
stdoutJournal = do
  lock <- newMVar ()
  pure
    Journal
      { write = \kind detail -> withMVar lock \_ -> do
          at <- getCurrentTime
          LBC.putStrLn (encode (object ["at" .= at, "kind" .= kind, "detail" .= detail]))
          hFlush stdout
      }

silentJournal :: Journal
silentJournal = Journal{write = \_ _ -> pure ()}
