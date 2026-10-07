---
title: Haskell
section: SDKs
order: 6
---

# Haskell

Package `peculiar-insights-sdk` under `sdk/haskell` in the repository, for backend services. `Insights` and `Tracker` are records of functions, so the application holds `Insights` in its `Env` behind `HasInsights` and a test substitutes a recording value of the same type. There is no mocking library and no global state.

## Installation

Add the package from this repository to `cabal.project` and depend on it.

```
source-repository-package
  type: git
  location: https://github.com/peculiar-systems/peculiar-insights
  subdir: sdk/haskell
```

```haskell
import Peculiar.Insights.Sdk
import Prelude hiding (log, span)
```

`Peculiar.Insights.Sdk` re-exports everything below. It defines `log` and `span`, hence the hiding.

### With Nix, and beside an HTTP/2 server of your own

The SDK speaks through peculiar-rpc, which pins its own HTTP/2 stack: http2 5.4, http-semantics 0.4, time-manager 0.3, wai and warp. One program links one such stack, so a service that depends on any of these builds on the transport's package set rather than on the stock one:

```nix
haskellPackages = import "${peculiar-rpc}/nix/haskell-packages.nix" { inherit lib pkgs; };
```

A service that only uses the SDK needs nothing more. One that serves HTTP/2 itself through `http2` meets three changes when it arrives on this stack from an older one:

- The timers run on GHC's timer manager, which exists only in the threaded runtime. Link every executable and test suite with `-threaded`; without it the first connection fails with "the TimerManager requires linking against the threaded runtime".
- `network-run` needs release 0.5, the first to build against time-manager 0.3.
- Since http2 5.3.11 a connection that receives no frame for the timeout manager's period, thirty seconds in `allocSimpleConfig`, is closed. A client that sends one request and then only listens to a stream is cut off, however much the server says to it. A server of long streams sets `confReadNTimeout = True` on its `Config` and watches each call through `auxTimeHandle` instead.

## Start

`withInsights` opens the connection, the sender thread and the queue, and flushes on the way out. `disabled` is an `Insights` of the same type that records nothing, for a deployment configured without a server; the application's `Env` does not change shape.

```haskell
main :: IO ()
main = withInsights config \insights -> run Env{insights}
 where
  config =
    (defaultConfig Endpoint{host = "insights.example.org", port = 443, tls = True} key "api-node-1" policy)
      { appVersion = "1.0.0"
      , appBuild = "20260101120000"
      , onDiagnostic = print
      }
```

`defaultConfig endpoint key service consent` fills the rest. The fields of `Config`:

| Field                 | Type                  | Default   | Meaning                                                                           |
| --------------------- | --------------------- | --------- | --------------------------------------------------------------------------------- |
| `endpoint`            | `Endpoint`            | required  | `host`, `port` and `tls`. With `tls` the system trust store validates the server. |
| `key`                 | `ByteString`          | required  | The ingest key. Read it from a file; never a literal in the tree.                 |
| `service`             | `Text`                | required  | The service's name, used as the process tracker's device id.                      |
| `consent`             | `ConsentPolicy`       | required  | `Assumed bases` or `Provided`.                                                    |
| `appVersion`          | `Text`                | `""`      | Reported in the context.                                                          |
| `appBuild`            | `Text`                | `""`      | Reported in the context.                                                          |
| `diagnostics`         | `Diagnostic -> IO ()` | ignore    | The sink for everything that goes wrong.                                          |
| `batchSize`           | `Int`                 | `200`     | Items per publish call.                                                           |
| `queueCapacity`       | `Int`                 | `10000`   | Bounded queue; beyond it items are dropped with a diagnostic.                     |
| `flushIntervalMicros` | `Int`                 | `5000000` | How often the sender drains the queue.                                            |
| `callTimeoutSeconds`  | `Integer`             | `20`      | Deadline of every call.                                                           |
| `logLimit`            | `Int`                 | `64`      | Breadcrumb lines kept for the next error.                                         |

Platform, operating system, architecture, locale and timezone are read from the host. `Insights` has these fields:

| Field           | Type                                                                      | What it does                                              |
| --------------- | ------------------------------------------------------------------------- | --------------------------------------------------------- |
| `tracker`       | `Tracker`                                                                 | The process tracker, whose subject is the service itself. |
| `subject`       | `Subject -> Consent -> Tracker`                                           | A tracker for one user, on a request.                     |
| `flush`         | `IO ()`                                                                   | Block until everything queued is sent.                    |
| `recordConsent` | `DeviceId -> Maybe UserId -> Purpose -> Grant -> IO (Either SdkError ())` | Record a grant or withdrawal directly.                    |
| `erase`         | `DeviceId -> Maybe UserId -> IO (Either SdkError ())`                     | Ask the server to erase a device and its linked person.   |

`HasInsights` is one class with one method, `getInsights :: env -> Insights`.

## Consent

Two purposes, `Analytics` and `Diagnostics`. A `Consent` is a record of `Maybe Grant` per purpose, where a `Grant` is `Granted version` or `Withdrawn version`; `noConsent` has neither, and `permits consent purpose` reads it.

- `Assumed Bases{analytics, diagnostics}` records each `Basis` given as a grant for the service's device at start, and the process tracker records under that consent. The basis text becomes the policy version in the ledger. A failed recording surfaces as a `TransportFailed` diagnostic.
- `Provided` means no process-level consent exists: the process tracker records nothing, and every tracker gets its consent from the request through `subject`.

A backend knows each user's decision from its own records, so there is no prompt and no buffer. A tracker whose consent does not permit an item's purpose drops it with a `NotConsented` diagnostic before it reaches the queue, and asserts in a build with assertions enabled.

### Withdrawal and erasure

An item carries the consent it was recorded under, and it may wait: in the queue, in a batch the server has not taken yet, in the spool. A decision made while it waits still applies to it.

`insights.recordConsent device user purpose (Withdrawn version)` first drops every item of that purpose recorded for that person up to this moment, from the queue, from what is being retried and from the spool, and then sends the withdrawal. `insights.erase device user` does the same for both purposes and then asks the server to erase. What was dropped is reported as `Dropped` with the cause `AfterWithdrawal` or `AfterErasure`. Items recorded afterwards are judged by the consent their tracker is given, which is the backend's to keep current.

Whose items they are is decided by the user when one is named: every item recorded for that user, on any device. Items without a user belong to the device, unless the device is the service's own name and a user was named, since a service records for many people under one name. A batch the server is answering at that very moment cannot be recalled.

## The tracker

`Tracker` is an immutable value. `with` folds properties into everything the tracker records; later properties win.

```haskell
let checkout = with ["screen" =: ("checkout" :: Text)] insights.tracker
```

| Function                            | Type                                     | What it does                                                                                                                   |
| ----------------------------------- | ---------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| `with`                              | `[Property] -> Tracker -> Tracker`       | A child tracker carrying the properties.                                                                                       |
| `track`                             | `Tracker -> Text -> [Property] -> IO ()` | Record an event.                                                                                                               |
| `identify`                          | `Tracker -> UserId -> IO ()`             | Link the tracker's device to a user.                                                                                           |
| `people`                            | `Tracker -> People`                      | `set`, `setOnce` and `unset :: [Text] -> IO ()`. Without a user on the subject the call is dropped with a `NoUser` diagnostic. |
| `recordError`                       | `Tracker -> ErrorReport -> IO ()`        | Record a report, adding the tracker's properties as custom keys and the recent log lines.                                      |
| `report`                            | `SomeException -> ErrorReport`           | Build a report from an exception with the call stack as frames; needs `HasCallStack`.                                          |
| `attempt`                           | `Tracker -> IO a -> IO a`                | Run an action; on any exception record it as non-fatal and rethrow.                                                            |
| `boundary`                          | `Tracker -> IO () -> IO ()`              | Run an action; on any exception record it and swallow. For loop boundaries.                                                    |
| `log`                               | `Tracker -> LogLevel -> Text -> IO ()`   | Add a breadcrumb line. `Debug`, `Info`, `Warning`, `Error`.                                                                    |
| `span`                              | `Tracker -> Text -> IO Span`             | Start a timer; `end :: [Property] -> IO ()` tracks the name with `duration_ms` added.                                          |
| `subjectOf`, `consentOf`, `scopeOf` |                                          | Read a tracker's subject, consent and properties.                                                                              |

Identifiers are newtypes: `UserId`, `DeviceId`, `SessionId` over `Text`. A `Subject` is `device`, `user :: Maybe UserId` and `session`.

## Per request

Derive a tracker from the identifiers the request carries and the consent the backend holds:

```haskell
handle :: (HasInsights env) => env -> Request -> IO ()
handle env request = do
  let subject = Subject{device = DeviceId request.deviceId, user = Just request.userId, session = SessionId request.id}
      tracker = with ["request" =: request.id] ((getInsights env).subject subject request.consent)
  identify tracker request.userId
  attempt tracker (charge request)
```

Use the device id a frontend SDK forwards when there is one, so both sides land on the same device; otherwise a stable anonymous id the backend minted.

## Values

Properties are a plain list of pairs built with `(=:)`, so no extension is needed and the operator does not collide with aeson's. The `IsProperty` class is closed: `Text`, `Int`, `Int64`, `Integer`, `Double`, `Bool`, `UTCTime`, lists of these, nested `Properties` built with `properties`, and a `Value` already built. Anything else is a type error, so nothing converts at runtime and nothing is dropped for its type.

```haskell
track tracker "order_placed" ["total" =: (42.5 :: Double), "items" =: (3 :: Int)]
```

Recording functions never throw. They enqueue and return; `flush` waits for delivery.

## Diagnostics

`onDiagnostic` in `Config` receives every `Diagnostic`:

| Constructor               | Fields                         | When                                                                                                                                                     |
| ------------------------- | ------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `Rejected Rejection`      | `item`, `outcome`, `reason`    | The server refused an item; the outcome is anything other than accepted or duplicate.                                                                    |
| `TransportFailed Failure` | `code`, `message`, `willRetry` | A call failed. Unavailable, unknown, deadline-exceeded and resource-exhausted are kept and sent again; the rest are not.                                 |
| `Dropped Drop`            | `count`, `cause`               | Items were not delivered. Causes: `QueueFull`, `NotConsented purpose`, `NoUser`, `AfterWithdrawal`, `AfterErasure`, and `NotDelivered`, described below. |
| `SpoolFailed Text`        | the reason                     | The spool could not be read or written; recording goes on in memory.                                                                                     |

## Capture

Nothing is installed automatically; a Haskell process decides its own boundaries. Wrap request handlers in `attempt` to record and rethrow, and loop bodies in `boundary` to record and continue. Both take the exception's type and message and the `HasCallStack` frames of the call site.

## Storage

Every item gets its id and its time when it is recorded, not when it is sent, so a late delivery keeps the moment it happened and a repeated one is recognised by the server.

The queue is bounded by `queueCapacity`. What cannot be delivered is kept and tried again, with exponential backoff or after the delay a rate-limiting server asks for; only a refusal that retrying cannot cure drops a batch, as `NotDelivered`. When more is waiting than the queue may hold, the oldest batches are dropped, also as `NotDelivered`.

With `spool = Just directory` in `Config`, every recorded item is written to that directory before the recording call returns and removed once the server has answered for it. A process that dies with items waiting, including the crash report of what killed it, leaves them on disk, and the next process with the same spool sends them first. Without a spool the queue is in memory: `withInsights` makes one delivery attempt when its block returns and reports what is left as dropped. One process per spool directory.

## Testing

`Peculiar.Insights.Sdk.Testing.recording policy subject` returns an `Insights` of the real record type together with two readers: the list of `Recorded{consent, item}` values and the list of diagnostics. Put it in `Env` in place of the real one. `recordingAt` takes a clock for deterministic spans.

```haskell
(insights, recorded, diagnosed) <- recording (Assumed Bases{analytics = Just (Basis "test"), diagnostics = Nothing}) subject
track insights.tracker "order_placed" ["total" =: (42.5 :: Double)]
items <- recorded
```

## Example

`sdk/haskell/example/Main.hs`

```haskell
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
```
