module Peculiar.Insights.Server.Uploads
  ( Uploads (..)
  , mkUploads
  , authorised
  ) where

import Data.ByteString qualified as BS
import Data.ByteString.Char8 qualified as BC
import Data.Char (toLower)
import Data.Map.Strict qualified as Map
import Data.Text qualified as T
import Peculiar.Rpc qualified as Rpc

data Uploads = Uploads
  { directory :: FilePath
  , maxBytes :: Int
  , projectOf :: BS.ByteString -> Maybe T.Text
  }

mkUploads :: FilePath -> Int -> [(BS.ByteString, T.Text)] -> Uploads
mkUploads directory maxBytes keys = Uploads{directory, maxBytes, projectOf = (`Map.lookup` table)}
 where
  table = Map.fromList keys

authorised :: Uploads -> Rpc.Context -> IO T.Text
authorised uploads context = case Rpc.lookupHeader "authorization" context.metadata of
  Nothing -> Rpc.throwRpc Rpc.Unauthenticated "no upload key was presented"
  Just value ->
    let (scheme, rest) = BC.break (== ' ') value
        key = BC.dropWhile (== ' ') rest
     in if BC.map toLower scheme /= "bearer" || BS.null key
          then Rpc.throwRpc Rpc.Unauthenticated "the authorization header is not a bearer key"
          else maybe (Rpc.throwRpc Rpc.Unauthenticated "the upload key is not known") pure (uploads.projectOf key)
