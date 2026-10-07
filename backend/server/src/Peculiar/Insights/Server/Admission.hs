module Peculiar.Insights.Server.Admission
  ( admit
  , peerOf
  , placed
  ) where

import Control.Exception (throwIO)
import Data.ByteString.Char8 qualified as BC
import Data.Foldable (for_)
import Data.Text qualified as T
import Data.Text.Encoding qualified as TE
import Peculiar.Insights.Core.Config (PeerLimit (..), Project (..))
import Peculiar.Insights.Core.Metrics (Series (..))
import Peculiar.Insights.Core.RateLimit (Verdict (..), pushbackMillis)
import Peculiar.Insights.Server.Clock (Clock (..))
import Peculiar.Insights.Server.Env
import Peculiar.Insights.Server.Limiter (Limiter (..), Scope (..))
import Peculiar.Insights.Server.Metrics (Metrics (..))
import Peculiar.Insights.Server.Projects (Registered (..))
import Peculiar.Rpc qualified as Rpc

admit :: (HasClock env, HasLimiter env, HasMetrics env) => env -> Rpc.Context -> Registered -> Int -> IO ()
admit env context registered cost = do
  now <- (getClock env).now
  let check scope rate named =
        (getLimiter env).admit scope rate now cost >>= \case
          Allowed -> pure ()
          Limited wait -> do
            (getMetrics env).count Series{name = "insights_rate_limited_total", labels = ("scope", named) : placed registered} 1
            throwIO
              Rpc.RpcError
                { Rpc.status = Rpc.Status{Rpc.code = Rpc.ResourceExhausted, Rpc.message = "the rate limit is exceeded, retry later", Rpc.details = []}
                , Rpc.metadata = Rpc.header "x-peculiar-retry-after-ms" (BC.pack (show (pushbackMillis wait)))
                }
  for_ (getPeerLimit env) \limit -> for_ (peerOf limit context) \peer -> check (OfPeer peer) limit.rate "peer"
  for_ registered.project.rateLimit \rate -> check (OfKey registered.id) rate "key"

peerOf :: PeerLimit -> Rpc.Context -> Maybe T.Text
peerOf limit context = case limit.forwardedHeader of
  Just name -> case Rpc.lookupHeader (TE.encodeUtf8 (T.toLower name)) context.metadata of
    Just value | address <- T.strip (T.takeWhile (/= ',') (TE.decodeUtf8Lenient value)), not (T.null address) -> Just address
    _ -> connected
  Nothing -> connected
 where
  connected = fmap (withoutPort . T.pack . show) context.peer
  withoutPort shown = case T.breakOnEnd ":" shown of
    ("", whole) -> whole
    (address, _) -> T.dropEnd 1 address

placed :: Registered -> [(T.Text, T.Text)]
placed registered = [("project", registered.project.slug), ("environment", registered.project.environment)]
