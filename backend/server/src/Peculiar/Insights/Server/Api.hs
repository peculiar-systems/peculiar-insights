{-# LANGUAGE TemplateHaskell #-}

module Peculiar.Insights.Server.Api
  ( IngestServer (..)
  , IngestClient (..)
  , ingest
  , authenticate
  , storing
  ) where

import Control.Monad (when)
import Data.Aeson (toJSON)
import Data.ByteString qualified as BS
import Data.ByteString.Char8 qualified as BC
import Data.Char (toLower)
import Data.Foldable (for_)
import Data.ProtoLens (defMessage)
import Data.ProtoLens.Labels ()
import Data.Text qualified as T
import Data.UUID.Types qualified as UUID
import Lens.Family2 ((&), (.~), (^.))
import Peculiar.Insights.Core.Ingest (Outcome (..), Policy (..), Rejection (..), describeRejection, plan)
import Peculiar.Insights.Core.Item (ItemId (..))
import Peculiar.Insights.Core.Item qualified as Core
import Peculiar.Insights.Core.Metrics (Series (..))
import Peculiar.Insights.Core.Time (skewBetween)
import Peculiar.Insights.Core.Validate (Limits (..))
import Peculiar.Insights.Server.Admission (admit, placed)
import Peculiar.Insights.Server.Clock (Clock (..))
import Peculiar.Insights.Server.Db (Db (..), DbError, Erased (..), Stored (..), describeDbError)
import Peculiar.Insights.Server.Env
import Peculiar.Insights.Server.Journal (Journal (..))
import Peculiar.Insights.Server.Metrics (Metrics (..))
import Peculiar.Insights.Server.Projects (Projects (..), Registered (..))
import Peculiar.Insights.Server.Proto (consentOf, erasureOf, fromItem, itemOutcome, snapshotOf, timeOf)
import Peculiar.Insights.Server.Symbolicate (symbolicateItems)
import Peculiar.Rpc qualified as Rpc
import Proto.Peculiar.Insights.V1.Ingest
import Proto.Peculiar.Insights.V1.Ingest qualified as Wire

Rpc.deriveService ''Ingest

type Serving env = (HasDb env, HasClock env, HasJournal env, HasProjects env, HasLimits env, HasLimiter env, HasMetrics env, HasSymbolicator env)

ingest :: (Serving env) => env -> IngestServer
ingest env =
  IngestServer
    { publish = publishing env
    , recordConsent = consenting env
    , requestErasure = erasing env
    }

authenticate :: (HasProjects env) => env -> Rpc.Context -> IO Registered
authenticate env context = do
  case Rpc.lookupHeader "x-peculiar-protocol" context.metadata of
    Just version | version /= "1" -> Rpc.throwRpc Rpc.FailedPrecondition "this SDK speaks a protocol version the server does not understand"
    _ -> pure ()
  case Rpc.lookupHeader "authorization" context.metadata of
    Nothing -> Rpc.throwRpc Rpc.Unauthenticated "no ingest key was presented"
    Just value ->
      let (scheme, rest) = BC.break (== ' ') value
          key = BC.dropWhile (== ' ') rest
       in if BC.map toLower scheme /= "bearer" || BS.null key
            then Rpc.throwRpc Rpc.Unauthenticated "the authorization header is not a bearer key"
            else maybe (Rpc.throwRpc Rpc.Unauthenticated "the ingest key is not known") pure ((getProjects env).byKey key)

data Planned
  = Malformed T.Text T.Text
  | Refused ItemId Rejection
  | Ready Core.Item

publishing :: (Serving env) => env -> Rpc.Context -> PublishRequest -> IO PublishResponse
publishing env context request = do
  registered <- authenticate env context
  now <- (getClock env).now
  let limits = getLimits env
      items = request ^. #items
  when (length items > limits.maxItems) (Rpc.throwRpc Rpc.InvalidArgument "the batch carries more items than allowed")
  admit env context registered (length items)
  let sentAt = maybe now timeOf (request ^. #maybe'sentAt)
      skew = skewBetween now sentAt
      consent = snapshotOf (request ^. #consent)
      policy = Policy{limits, window = getWindow env, consent, skew, now}
      planned = fmap (planOne policy . fromItem) items
      ready = [item | Ready item <- planned]
  symbolicated <- symbolicateItems env registered ready
  stored <- storing env "publish" ((getDb env).publish registered now ready symbolicated)
  let answered = outcomes planned stored
  for_ answered \outcome ->
    (getMetrics env).count Series{name = "insights_items_total", labels = ("outcome", outcomeLabel (outcome ^. #outcome)) : placed registered} 1
  pure (defMessage & #outcomes .~ answered)

outcomeLabel :: Wire.Outcome -> T.Text
outcomeLabel = \case
  OUTCOME_ACCEPTED -> "accepted"
  OUTCOME_DUPLICATE -> "duplicate"
  OUTCOME_NOT_CONSENTED -> "not_consented"
  _ -> "invalid"

planOne :: Policy -> (T.Text, Either T.Text Core.Item) -> Planned
planOne policy (raw, converted) = case converted of
  Left reason -> Malformed raw reason
  Right item -> case plan policy item of
    Accepted accepted -> Ready accepted
    Rejected itemId rejection -> Refused itemId rejection

outcomes :: [Planned] -> [Stored] -> [ItemOutcome]
outcomes = go
 where
  go [] _ = []
  go (Malformed raw reason : rest) remaining = itemOutcome raw OUTCOME_INVALID reason : go rest remaining
  go (Refused itemId rejection : rest) remaining = itemOutcome (idText itemId) (code rejection) (describeRejection rejection) : go rest remaining
  go (Ready _ : rest) (Stored itemId : remaining) = itemOutcome (idText itemId) OUTCOME_ACCEPTED "" : go rest remaining
  go (Ready _ : rest) (Duplicate itemId : remaining) = itemOutcome (idText itemId) OUTCOME_DUPLICATE "" : go rest remaining
  go (Ready _ : rest) [] = go rest []
  code = \case
    Invalid _ -> OUTCOME_INVALID
    NotConsented _ -> OUTCOME_NOT_CONSENTED
    OutOfWindow _ -> OUTCOME_INVALID

idText :: ItemId -> T.Text
idText (ItemId uuid) = UUID.toText uuid

storing :: (HasJournal env, HasMetrics env) => env -> T.Text -> IO (Either DbError b) -> IO b
storing env what action =
  action >>= \case
    Right result -> pure result
    Left failure -> do
      (getJournal env).write (what <> "-failed") (toJSON (describeDbError failure))
      (getMetrics env).count Series{name = "insights_storage_failures_total", labels = [("operation", what)]} 1
      Rpc.throwRpc Rpc.Unavailable "storage is unavailable, retry later"

consenting :: (Serving env) => env -> Rpc.Context -> RecordConsentRequest -> IO RecordConsentResponse
consenting env context request = do
  registered <- authenticate env context
  admit env context registered 1
  now <- (getClock env).now
  record <- either (Rpc.throwRpc Rpc.InvalidArgument) pure (consentOf request)
  stored <- storing env "consent" ((getDb env).recordConsent registered now record)
  pure
    ( defMessage
        & #outcome .~ case stored of
          Stored _ -> OUTCOME_ACCEPTED
          Duplicate _ -> OUTCOME_DUPLICATE
    )

erasing :: (Serving env) => env -> Rpc.Context -> RequestErasureRequest -> IO RequestErasureResponse
erasing env context request = do
  registered <- authenticate env context
  admit env context registered 1
  now <- (getClock env).now
  erasure <- either (Rpc.throwRpc Rpc.InvalidArgument) pure (erasureOf request)
  erased <- storing env "erasure" ((getDb env).erase registered now erasure)
  pure
    ( defMessage
        & #outcome .~ case erased of
          Erased -> OUTCOME_ACCEPTED
          ErasureDuplicate -> OUTCOME_DUPLICATE
    )
