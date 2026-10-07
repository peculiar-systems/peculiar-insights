module Main (main) where

import Data.Text qualified as T
import Peculiar.Insights.Sdk
import Prelude hiding (log, span)

data Env = Env
  { insights :: Insights
  , region :: T.Text
  }

instance HasInsights Env where
  getInsights env = env.insights

data Request = Request
  { requestId :: T.Text
  , userId :: UserId
  , userConsent :: Consent
  , total :: Double
  }

main :: IO ()
main = withInsights config \insights -> do
  let env = Env{insights, region = "eu"}
  track insights.tracker "service_started" ["runtime" =: ("ghc" :: T.Text)]
  handleOrder env Request{requestId = "request-42", userId = UserId "user-123", userConsent = granted, total = 42.5}
 where
  config =
    (defaultConfig Endpoint{host = "insights.example.org", port = 443, tls = True} "replace-with-the-ingest-key" "api-node-1" policy)
      { appVersion = "1.0.0"
      , appBuild = "20260101120000"
      , onDiagnostic = print
      }
  policy = Assumed Bases{analytics = Just (Basis "service-telemetry"), diagnostics = Just (Basis "service-telemetry")}
  granted = Consent{analytics = Just (Granted "2026-01"), diagnostics = Just (Granted "2026-01")}

handleOrder :: (HasInsights env) => env -> Request -> IO ()
handleOrder env request = do
  let subject = Subject{device = DeviceId "api-node-1", user = Just request.userId, session = SessionId request.requestId}
      tracker = with ["request" =: request.requestId] ((getInsights env).subject subject request.userConsent)
  identify tracker request.userId
  (people tracker).setOnce ["first_order_at" =: ("2026-01-01" :: T.Text)]
  checkout <- span tracker "checkout"
  log tracker Info "charging the card"
  attempt tracker (charge request.total)
  checkout.end ["total" =: request.total, "items" =: (3 :: Int)]

charge :: Double -> IO ()
charge total
  | total > 1000 = ioError (userError "payment declined")
  | otherwise = pure ()
