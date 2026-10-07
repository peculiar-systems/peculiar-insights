module Peculiar.Insights.Sdk.Spool
  ( Record (..)
  , Queued (..)
  , Spool (..)
  , frame
  , unframe
  , surviving
  , encodeQueued
  , decodeQueued
  , noSpool
  , openSpool
  ) where

import Control.Concurrent.MVar (MVar, modifyMVar_, newMVar)
import Control.Exception (IOException, try)
import Control.Monad (when)
import Data.Bits (shift, (.&.), (.|.))
import Data.ByteString qualified as BS
import Data.Foldable (for_)
import Data.Map.Strict qualified as Map
import Data.ProtoLens (decodeMessage, defMessage, encodeMessage)
import Data.ProtoLens.Labels ()
import Data.Set qualified as Set
import Data.Text qualified as T
import Data.Text.Encoding qualified as TE
import Lens.Family2 ((&), (.~), (^.))
import Peculiar.Insights.Sdk.Encode (decodeConsent, encodeConsent, itemIdentifier)
import Peculiar.Insights.Sdk.Types (Consent)
import Proto.Peculiar.Insights.V1.Ingest qualified as P
import System.Directory (createDirectoryIfMissing, doesFileExist, renameFile)
import System.FilePath ((</>))
import System.IO (Handle, IOMode (..), hClose, hFlush, hSetFileSize, openBinaryFile)

data Queued = Queued
  { identifier :: T.Text
  , consent :: Consent
  , item :: P.Item
  }
  deriving stock (Eq, Show)

data Record
  = Put BS.ByteString
  | Ack T.Text
  deriving stock (Eq, Show)

data Spool = Spool
  { put :: Queued -> IO ()
  , acknowledge :: [T.Text] -> IO ()
  , close :: IO ()
  }

noSpool :: Spool
noSpool = Spool{put = const (pure ()), acknowledge = const (pure ()), close = pure ()}

frame :: Record -> BS.ByteString
frame = \case
  Put payload -> BS.cons 0x50 (sized payload)
  Ack identifier -> BS.cons 0x41 (sized (TE.encodeUtf8 identifier))
 where
  sized payload = BS.pack [fromIntegral (shift (BS.length payload) (negate places) .&. 0xff) | places <- [24, 16, 8, 0]] <> payload

unframe :: BS.ByteString -> [Record]
unframe bytes = case BS.uncons bytes of
  Just (tag, rest)
    | BS.length rest >= 4
    , size <- BS.foldl' (\total byte -> shift total 8 .|. fromIntegral byte) 0 (BS.take 4 rest)
    , (payload, after) <- BS.splitAt size (BS.drop 4 rest)
    , BS.length payload == size ->
        case tag of
          0x50 -> Put payload : unframe after
          0x41 -> Ack (TE.decodeUtf8Lenient payload) : unframe after
          _ -> []
  _ -> []

encodeQueued :: Queued -> BS.ByteString
encodeQueued queued = encodeMessage ((defMessage :: P.PublishRequest) & #consent .~ encodeConsent queued.consent & #items .~ [queued.item])

decodeQueued :: BS.ByteString -> Maybe Queued
decodeQueued payload = case decodeMessage payload of
  Right (request :: P.PublishRequest)
    | [item] <- request ^. #items
    , Just identifier <- itemIdentifier item ->
        Just Queued{identifier, consent = decodeConsent (request ^. #consent), item}
  _ -> Nothing

surviving :: [Record] -> [Queued]
surviving records = [queued | Put payload <- records, Just queued <- [decodeQueued payload], not (Set.member queued.identifier acknowledged)]
 where
  acknowledged = Set.fromList [identifier | Ack identifier <- records]

data Held = Held
  { handle :: Handle
  , waiting :: Map.Map T.Text BS.ByteString
  , settled :: Int
  }

openSpool :: (T.Text -> IO ()) -> FilePath -> IO (Spool, [Queued])
openSpool complain directory =
  try @IOException opening >>= \case
    Left failure -> (noSpool, []) <$ complain (T.pack (show failure))
    Right (held, replayed) -> do
      state <- newMVar held
      pure
        ( Spool
            { put = \queued -> guarded state \current -> do
                let payload = encodeQueued queued
                written current (frame (Put payload))
                pure current{waiting = Map.insert queued.identifier payload current.waiting}
            , acknowledge = \identifiers -> guarded state \current -> do
                let known = filter (`Map.member` current.waiting) identifiers
                    left = foldr Map.delete current.waiting known
                    next = current{waiting = left, settled = current.settled + length known}
                if Map.null left
                  then emptied next
                  else do
                    for_ known (written current . frame . Ack)
                    pure next
            , close = guarded state \current -> current <$ hClose current.handle
            }
        , replayed
        )
 where
  path = directory </> "queue"
  opening = do
    createDirectoryIfMissing True directory
    present <- doesFileExist path
    replayed <- if present then surviving . unframe <$> BS.readFile path else pure []
    let compacted = BS.concat (fmap (frame . Put . encodeQueued) replayed)
    BS.writeFile (path <> ".next") compacted
    renameFile (path <> ".next") path
    handle <- openBinaryFile path AppendMode
    pure (Held{handle, waiting = Map.fromList [(queued.identifier, encodeQueued queued) | queued <- replayed], settled = 0}, replayed)
  written current bytes = BS.hPut current.handle bytes *> hFlush current.handle
  emptied current = do
    when (current.settled > 0) (hSetFileSize current.handle 0)
    pure current{settled = 0}
  guarded :: MVar Held -> (Held -> IO Held) -> IO ()
  guarded state change =
    try @IOException (modifyMVar_ state change) >>= \case
      Right () -> pure ()
      Left failure -> complain (T.pack (show failure))
