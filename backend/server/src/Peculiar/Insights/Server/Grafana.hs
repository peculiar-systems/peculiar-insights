module Peculiar.Insights.Server.Grafana
  ( Grafana (..)
  , HasGrafana (..)
  , Refusal (..)
  , describeRefusal
  , identityHeader
  , admit
  , grafanaOf
  , absentGrafana
  ) where

import Control.Exception (SomeException, try)
import Control.Monad (void)
import Crypto.JWT (Alg (ES256), ClaimsSet, JOSE, JWKSet, JWTError (..), SignedJWT, algorithms, decodeCompact, defaultJWTValidationSettings, runJOSE, verifyClaimsAt, verifyJWSWithPayload)
import Data.Aeson (FromJSON, eitherDecode, eitherDecodeStrict)
import Data.Bifunctor (first)
import Data.ByteString qualified as BS
import Data.ByteString.Lazy qualified as LBS
import Data.Functor.Identity (Identity, runIdentity)
import Data.Maybe (fromMaybe)
import Data.Set qualified as Set
import Data.String (fromString)
import Data.Text qualified as T
import Data.Time (UTCTime)
import GHC.Generics (Generic, Generically (..))
import Lens.Family2 ((&), (.~))
import Network.HTTP.Client (HttpException, Manager, httpLbs, parseRequest, responseBody, responseStatus)
import Network.HTTP.Client.TLS (newTlsManager)
import Network.HTTP.Types (statusIsSuccessful)
import Peculiar.Insights.Core.Config qualified as Config

data Grafana = Grafana
  { organization :: Int
  , signingKeys :: IO (Either Refusal JWKSet)
  }

class HasGrafana env where
  getGrafana :: env -> Grafana

data Refusal
  = Unlinked
  | Anonymous
  | KeysUnavailable T.Text
  | Unverified JWTError
  | NotAdmin (Maybe T.Text)
  deriving stock (Eq, Show)

newtype Signed = Signed
  { role :: Maybe T.Text
  }
  deriving stock (Generic)
  deriving (FromJSON) via Generically Signed

describeRefusal :: Refusal -> T.Text
describeRefusal = \case
  Unlinked -> "this server is linked to no Grafana"
  Anonymous -> "the request carries no Grafana identity"
  KeysUnavailable reason -> "Grafana's signing keys are unavailable: " <> reason
  Unverified failure -> "the Grafana identity does not verify: " <> T.pack (show failure)
  NotAdmin role -> "only a Grafana Admin may do this, and this identity's role is " <> fromMaybe "none" role

identityHeader :: BS.ByteString
identityHeader = "x-grafana-id"

admit :: Int -> UTCTime -> JWKSet -> BS.ByteString -> Either Refusal ()
admit organization now keys token = do
  decoded <- first Unverified (runIdentity (runJOSE verified))
  signed <- first (Unverified . JWTClaimsSetDecodeError) decoded
  if signed.role == Just "Admin" then Right () else Left (NotAdmin signed.role)
 where
  settings =
    defaultJWTValidationSettings (== fromString ("org:" <> show organization))
      & algorithms .~ Set.singleton ES256
  verified = do
    jwt <- decodeCompact @SignedJWT (LBS.fromStrict token)
    void (verifyClaimsAt settings keys now jwt :: JOSE JWTError Identity ClaimsSet)
    verifyJWSWithPayload (pure . eitherDecode @Signed) settings keys jwt

linkedGrafana :: Manager -> Config.Grafana -> Either T.Text Grafana
linkedGrafana manager linked = do
  request <- first (T.pack . show) (parseRequest @(Either SomeException) (T.unpack (T.dropWhileEnd (== '/') linked.url <> "/api/signing-keys/keys")))
  pure
    Grafana
      { organization = linked.organization
      , signingKeys =
          try @HttpException (httpLbs request manager) >>= \case
            Left failure -> pure (Left (KeysUnavailable (T.pack (show failure))))
            Right response
              | statusIsSuccessful (responseStatus response) -> pure (first (KeysUnavailable . T.pack) (eitherDecodeStrict (LBS.toStrict (responseBody response))))
              | otherwise -> pure (Left (KeysUnavailable ("Grafana answered " <> T.pack (show (responseStatus response)))))
      }

grafanaOf :: Maybe Config.Grafana -> IO (Either T.Text Grafana)
grafanaOf = \case
  Nothing -> pure (Right absentGrafana)
  Just linked -> (`linkedGrafana` linked) <$> newTlsManager

absentGrafana :: Grafana
absentGrafana = Grafana{organization = 0, signingKeys = pure (Left Unlinked)}
