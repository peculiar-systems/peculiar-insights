module Peculiar.Insights.Core.Fingerprint
  ( Fingerprint (..)
  , fingerprint
  , title
  , normalizeMessage
  ) where

import Crypto.Hash.SHA256 qualified as SHA256
import Data.ByteString.Base16 qualified as Base16
import Data.Char (isDigit, isHexDigit)
import Data.Text qualified as T
import Data.Text.Encoding qualified as TE
import Peculiar.Insights.Core.Item (Frame (..))

newtype Fingerprint = Fingerprint T.Text
  deriving stock (Eq, Ord, Show)

fingerprint :: T.Text -> T.Text -> [Frame] -> Fingerprint
fingerprint exceptionType message frames =
  Fingerprint (TE.decodeUtf8 (Base16.encode (SHA256.hash (TE.encodeUtf8 material))))
 where
  material = T.intercalate "\n" (exceptionType : body)
  body = case significant frames of
    [] -> [normalizeMessage message]
    chosen -> fmap location chosen

significant :: [Frame] -> [Frame]
significant frames = take 5 case filter (.inApp) frames of
  [] -> frames
  inApp -> inApp

location :: Frame -> T.Text
location frame
  | T.null frame.function = frame.moduleName <> ":" <> frame.file
  | otherwise = frame.moduleName <> "." <> frame.function

title :: T.Text -> T.Text -> [Frame] -> T.Text
title exceptionType message frames = case significant frames of
  frame : _ | not (T.null (location frame)) -> exceptionType <> " in " <> location frame
  _ -> T.strip (exceptionType <> ": " <> T.take 120 (normalizeMessage message))

normalizeMessage :: T.Text -> T.Text
normalizeMessage = T.unwords . fmap collapse . T.words
 where
  collapse word
    | T.all isDigit word = "#"
    | T.length word >= 8 && T.all isHexDigit word = "#"
    | otherwise = T.map (\c -> if isDigit c then '#' else c) word
