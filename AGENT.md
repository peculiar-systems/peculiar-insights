# Integrating Peculiar Insights

This document is written for an agent that has been asked to add Peculiar
Insights, a self-hosted analytics and crash tracking system, to a product.
It is complete: everything you need is here or in the repository files it
names. Read it fully before touching the product. Work through the
sections in order, and finish with the checklist at the end; you are done
only when every item on it holds.

## 1. What you are integrating

Peculiar Insights records three kinds of things about a product:

- **Events**: what a user did, as a name and a small map of properties.
- **People**: profile properties that describe a user rather than a moment.
- **Errors**: handled failures and crashes, grouped into issues on the server.

Events, people and sessions belong to the `analytics` purpose. Errors and
their breadcrumb logs belong to the `diagnostics` purpose. A user grants or
withdraws each purpose separately, and the SDK sends nothing for a purpose
that is not granted. The server independently refuses anything whose
purpose is not granted, so a mistake in the product cannot store data it
should not have.

Everything the product records ends up in Grafana dashboards run by the
operator: event segmentation, funnels, retention, people, crashes, issues,
consent. There is no other frontend, and there is nothing to configure on
the server for a new event: an event exists the first time it is tracked.

## 2. What to ask for before you start

Stop and ask if any of these is missing. Do not guess them.

1. **The server URL** for each environment, such as `https://insights.example.org`.
2. **The ingest key** for each environment. It is write-only and may be
   embedded in a mobile app or a browser bundle. In a backend it is still
   a secret: read it from an environment variable or a file, never commit
   it, never log it.
3. **The privacy policy version** string, such as `2026-01`. It is sent
   with every consent grant and must change whenever the policy changes.
4. **The product's own packages or modules**, used to mark stack frames as
   in-app so crashes group by the product's code and not by framework code.
5. **The consent approach**: does the product show a consent prompt, or
   does it have a legal basis that needs no prompt? Only the product's
   owner can answer this. Do not decide it yourself.
6. **The stable user id** the product already has for logged-in users.
7. **For a Flutter product, the project's symbols upload key** and where
   the product's build or CI keeps its secrets. It is a secret for builds
   only: never put it in the app, never commit it, never log it.

## 3. Rules that are not negotiable

- **Nothing before consent.** Never track, identify or capture errors
  before the user has decided, and never grant a purpose in code to make
  data appear. The only way consent is granted is a real decision by the
  user through the product's prompt, or a legal basis stated by the
  product's owner through `ConsentPolicy.assumed`.
- **Two purposes, offered honestly.** Offer analytics and diagnostics
  separately, or as one choice only if the product's policy says so.
- **A denial sends nothing.** Do not call withdraw for a user who never
  granted. Withdraw is for a user who granted earlier and changes their mind.
- **No personal data in names, properties, keys or log lines.** Emails,
  names, phone numbers, addresses, message bodies and anything a user
  typed do not belong in analytics. User ids are the product's opaque ids.
- **Do not wrap the SDK in your own abstraction.** A child tracker from
  `with` is the abstraction. Call the SDK from the code that owns the
  behaviour being measured.
- **Do not invent properties.** Every property must be a value the product
  already computes at that point in the code.
- **Analytics must never break the product.** The SDK never throws in
  release builds; do not add `try` blocks around it, and do not `await`
  it in a way that delays user-visible work when a fire-and-forget call
  is available.

## 4. The shape of every SDK

Two objects, identical in every language:

- **`Insights`** is the process. It is created once with the URL, the key
  and a consent policy. It owns the connection, the queue, consent, the
  session and the diagnostics stream. There is one per process.
- **`Tracker`** records. It is bound to a subject, meaning a device, an
  optional user and a session, and to that subject's consent. In Flutter
  and the browser, `insights.tracker` is the device-bound tracker and the
  only one you need. On a backend, `insights.subject(subject, consent)`
  derives a tracker per request from the identifiers and the consent the
  backend holds for that user.

Trackers are immutable values. `tracker.with({...})` returns a child whose
properties fold into every event and error the child records; the child's
own properties win over the parent's. Use children for a screen, a flow or
a request. There is no global mutable context anywhere.

The vocabulary is the same in every language:

| Name | Where | What it does |
|---|---|---|
| `start` | `Insights` | Creates the process object; needs URL, key, consent policy |
| `tracker` | `Insights` | The device-bound tracker |
| `subject` | `Insights` | A tracker for a given subject and consent, on backends |
| `consent` | `Insights` | `grant`, `withdraw`, `status` |
| `diagnostics` | `Insights` | The stream of everything that went wrong |
| `flush` | `Insights` | Send everything queued now |
| `close` | `Insights` | Flush and release; `dispose` in TypeScript |
| `erase` | `Insights` | Ask the server to delete this device and its linked person |
| `with` | `Tracker` | A child tracker with folded-in properties; `with_` in Dart |
| `track` | `Tracker` | Record an event by name with properties |
| `identify` | `Tracker` | Link the device to a `UserId` |
| `reset` | `Tracker` | Forget the user and mint a new device id |
| `people` | `Tracker` | `set`, `setOnce`, `unset` profile properties |
| `recordError` | `Tracker` | Record a handled or fatal error |
| `attempt` | `Tracker` | Run an action, record a non-fatal error if it fails, rethrow |
| `log` | `Tracker` | Add a breadcrumb line attached to the next error |
| `span` | `Tracker` | Start a timer; `end` tracks the event with `duration_ms` |

Values are the language's own: numbers, strings, booleans, dates, lists
and nested maps. Nothing else converts. TypeScript rejects other types at
compile time. Dart and Haskell convert at runtime; an unconvertible value
asserts in a debug build and is dropped with a diagnostic in release.

Identifiers are typed: `UserId`, `DeviceId`, `SessionId`. Wrap the
product's id explicitly. If you find yourself wrapping an email, stop.

## 5. Designing what to record

### Events

- Names are `snake_case`, past tense, describing what the user did:
  `checkout_opened`, `order_placed`, `search_performed`, `plan_upgraded`.
  Not `click_button`, not `CheckoutScreen`, not `error`.
- One event per meaningful decision or outcome. Do not track renders,
  scrolls, hovers or every keystroke.
- Properties are flat and few: the values that will be split on in a
  dashboard. `{"total": 42.5, "items": 3, "gift": false}`. Amounts as
  numbers, not formatted strings. Booleans as booleans.
- Use the same name and property keys for the same event on every
  platform. Funnels and retention group by name.
- Put context on a child tracker, not on every call:
  `screen.track(...)` where `screen = tracker.with({"screen": "checkout"})`.

### Identity

- Call `identify(UserId(...))` the moment the product knows the user, on
  login and on session restore. Earlier anonymous events on the device are
  linked to the person by the server; you lose nothing by identifying late.
- Call `reset()` on logout so the next person on the device starts clean.
- Anonymous users need nothing. The device id is minted automatically.
- On a backend, use the device id the frontend SDK exposes and forwards
  in requests if there is one, so both sides land on the same device.
  Otherwise mint a UUID per anonymous visitor, keep it in the session or a
  cookie, and use it as the `DeviceId`. Jobs and startup use
  `insights.tracker`, whose subject is the service itself.

### People

- `people.set` merges properties that describe the person: plan, locale,
  role, cohort. `people.setOnce` keeps the first value, for a signup date.
  `people.unset` removes keys. Counters are not profile properties; they
  are events, aggregated in Grafana.
- People calls need an identified user. Without one they are dropped with
  a diagnostic.

### Errors

- `recordError(error, stack)` for a handled failure the product cares
  about: a payment that was declined, a sync that failed.
- `attempt(action)` around an action whose failure matters. It records a
  non-fatal error with the failure and rethrows, so control flow is
  unchanged.
- `log(message)` lines are breadcrumbs attached to the next recorded error
  from the same tracker. Use them for state that explains a failure, never
  for personal data.
- Unhandled errors are captured automatically in Flutter, the browser and
  Node. In Haskell wrap loop boundaries with `boundary`.

### Time

- `span(name)` starts a timer; `span.end({...})` tracks `name` with a
  `duration_ms` property. Use it for flows: checkout, onboarding, a sync.
  Do not compute durations by hand.

### Sessions

Automatic on every platform. Never model them yourself.

## 6. Flutter

Example: `sdk/dart/peculiar_insights_flutter/example/main.dart`.

**Dependencies.** Add `peculiar_insights` and `peculiar_insights_flutter`
from `sdk/dart` of this repository as path or git dependencies.

**Start.** In `main`, before `runApp`:

```dart
final insights = await FlutterInsights.start(
  url: Uri.parse(serverUrl),
  key: ingestKey,
  consent: const ConsentPolicy.ask(),
  inAppPackages: const ["shop"],
  trackAppLifecycle: true,
);
runApp(ShopApp(insights: insights));
```

`FlutterInsights.start` reads the app version and build, fills the
platform context, installs `FlutterError.onError`,
`PlatformDispatcher.onError` and isolate error capture, wires sessions to
the app lifecycle, and returns an `Insights`. Keep it for the app's
lifetime and pass it down; do not put it in a global.

**Consent.** With `ConsentPolicy.ask()`, the product's consent screen
calls:

```dart
await insights.consent.grant(Purpose.analytics, policyVersion: "2026-01");
await insights.consent.grant(Purpose.diagnostics, policyVersion: "2026-01");
```

and `insights.consent.withdraw(Purpose.analytics)` when a user changes
their mind. `insights.consent.status` tells the settings screen what to
show. Until a decision, events are buffered in memory only and nothing is
written or sent; a grant persists and flushes them, a denial discards them.

**Screens.** Add `InsightsNavigatorObserver(insights)` to
`navigatorObservers` and `screen_viewed` is tracked on every route change.
For code inside a screen, derive a child once:

```dart
final checkout = insights.tracker.with_({"screen": "checkout"});
await checkout.track("checkout_opened", {"items": 3, "total": 42.5});
```

**Identity.** `await insights.tracker.identify(const UserId("u-123"))`
after login; `await insights.tracker.reset()` on logout.

**Errors.** Automatic capture is installed. For handled failures:

```dart
await checkout.attempt(() => pay(order));
```

**Web.** Persistence on Flutter web needs the drift wasm assets served by
the app and passed as `sqlite3Wasm` and `driftWorker`; without them the
SDK runs in memory and loses its queue on reload.

**Erasure.** `await insights.erase()` behind the product's account
deletion flow.

**Tests.** Start `Insights` with `transport: RecordingTransport()` and a
`MemoryStorage()` in widget or unit tests, then assert on
`recording.eventNames` or `recording.events`.

**Symbols.** Release builds report traces the server reads only with the
build's symbols, so add their upload to the product's build or CI, after
every release build of every platform it ships, with the build number the
build was given:

```sh
nix run "$INSIGHTS_FLAKE#peculiar-insights-upload-symbols" -- \
  --server "$INSIGHTS_URL" --project shop --build "$BUILD_NUMBER" \
  --key-file "$UPLOAD_KEY_FILE" \
  --dart-symbols build/symbols \
  --r8-mapping build/app/outputs/mapping/release/mapping.txt
```

Pass every kind the build produces: `--dart-symbols` for the directory
given to `--split-debug-info`, `--web-source-maps` for a web build made
with `--source-maps`, `--r8-mapping` and `--ndk-symbols` for Android,
`--dsyms` for iOS. A later upload for the same build replaces the kinds it
carries, so all Dart symbols of one build number go in one upload. The
site's Uploading symbols page lists where each toolchain leaves them.

**Pure Dart.** A Dart server or CLI uses `Insights.start` directly with
`app: AppInfo(version:, build:)`, a `storage` and a `ConsentPolicy`, and
derives trackers with `insights.subject`; see
`sdk/dart/peculiar_insights/example/main.dart`.

## 7. TypeScript in the browser

Example: `sdk/ts/examples/browser.ts`.

**Dependencies.** Add the `peculiar-insights` package from `sdk/ts` and
import from `peculiar-insights/browser`.

**Start.** Once, at application startup:

```ts
const insights = await createInsights({
  url: serverUrl,
  key: ingestKey,
  app: { version: APP_VERSION, build: APP_BUILD },
  consent: ConsentPolicy.ask(),
});
```

The version and build are the one thing the browser cannot know; inject
them at build time. The client uses gRPC-Web, stores its queue in
IndexedDB, captures `error` and `unhandledrejection`, flushes on page
hide, and treats Global Privacy Control as a denial of both purposes
unless the product overrides it.

**Consent.** The product's banner calls
`insights.consent.grant("analytics", "2026-01")` and the same for
`"diagnostics"`; `insights.consent.withdraw(purpose)` on change;
`insights.consent.status()` for the settings page.

**Recording.**

```ts
const checkout = insights.tracker.with({ screen: "checkout" });
await checkout.track("checkout_opened", { items: 3, total: 42.5 });
await checkout.identify(UserId("u-123"));
await checkout.people.set({ plan: "pro" });
await checkout.attempt(() => pay(order));
const timing = checkout.span("checkout_completed");
await timing.end({ provider: "card" });
```

Opt in to `trackRoutes(insights)` for `screen_viewed` on history changes
and `trackVisibility(insights)` for foreground and background events.

**Server side.** The operator must list the product's origin in the
server's CORS origins, or every call fails as a network error.

**Tests.** Create the client with `transport: recordingTransport()` and
assert on `events()` and `errors()` of the recorder. `insights.diagnostics`
takes a listener and returns an unsubscribe function.

## 8. TypeScript in Node

Example: `sdk/ts/examples/node.ts`.

Import from `peculiar-insights/node`. Create one `Insights` with a
`stateDirectory` the process can write, the version and build from the
package, and a consent policy for the service's own telemetry, typically
`ConsentPolicy.assumed({ analytics: "service-telemetry", diagnostics: "service-telemetry" })`.
`insights.tracker` records the service's own events and crashes.

For end users, derive a tracker per request:

```ts
const tracker = insights.subject(
  { deviceId: DeviceId(request.deviceId), userId: UserId(request.userId), sessionId: SessionId(request.id) },
  consentFor(request.user),
);
await tracker.track("order_placed", { total: 42.5 });
```

`consentFor` is the product's own lookup of what that user granted; the
backend is the source of truth for its users' consent, and
`grantedConsent({ analytics: "2026-01", diagnostics: "2026-01" })` builds
the value from the policy versions it holds. Items whose purpose is not
granted are dropped before they are queued. Flush on `SIGTERM`.

## 9. Haskell

Example: `sdk/haskell/example/Main.hs`.

**Dependency.** `peculiar-insights-sdk` from `sdk/haskell`. Import
`Peculiar.Insights.Sdk` with `Prelude hiding (log, span)`.

**Start.** Open one `Insights` per process and hold it in the
application's environment behind `HasInsights`, following the loop-skills
Haskell conventions. When the server is optional in configuration, pass
`disabled` in its place: the same type, recording nothing.

```haskell
data Env = Env { insights :: Insights, ... }

instance HasInsights Env where
  getInsights env = env.insights

main = withInsights config \insights -> run Env{insights, ...}
 where
  config =
    (defaultConfig Endpoint{host, port = 443, tls = True} key "api" policy)
      { appVersion = "1.0.0", appBuild = build, onDiagnostic = journal, spool = Just "/var/lib/service/insights" }
  policy = Assumed Bases{analytics = Just (Basis "service-telemetry"), diagnostics = Just (Basis "service-telemetry")}
```

`Assumed` records the bases as automatic grants at start and lets the
process tracker record the service's own telemetry. `Provided` means no
process-level consent exists and every tracker gets its consent from the
request.

**Per request.**

```haskell
handle :: (HasInsights env) => env -> Request -> IO ()
handle env request = do
  let subject = Subject{device = DeviceId request.deviceId, user = Just request.userId, session = SessionId request.id}
      tracker = with ["request" =: request.id] ((getInsights env).subject subject request.consent)
  identify tracker request.userId
  checkout <- span tracker "checkout"
  attempt tracker (charge request)
  checkout.end ["total" =: request.total, "items" =: (3 :: Int)]
```

Properties are a plain list, `["total" =: 42.5, "items" =: (3 :: Int)]`;
`(=:)` does not collide with aeson's `(.=)`. A service that
serves HTTP/2 itself builds on the transport's package set and is linked
with the threaded runtime; the Haskell SDK page says why and what else
changes. Give `spool` a directory the
service owns so that what is queued, a crash report included, survives the
process. `attempt` records the exception
with its call stack as frames and rethrows; `boundary` records and
swallows, for loop boundaries. `(people tracker).set` and `.setOnce` take
the same properties.

**Withdrawal.** When a user changes their mind, call
`insights.recordConsent device user purpose (Withdrawn version)`, and
`insights.erase device user` when they ask to be forgotten. Both drop what
is still waiting for that person before anything is sent. From then on
build that user's trackers with the consent as it now stands.

**Tests.** `Peculiar.Insights.Sdk.Testing.recording` returns an `Insights`
of the same record type plus readers for what was recorded and diagnosed;
put it in `Env` in place of the real one.

## 10. Consent prompts

If the product shows a prompt, the agent implements it in the product's
own UI toolkit. Requirements:

- Two choices the user can make independently, or one combined choice
  only if the product's policy says so.
- No pre-ticked boxes, no dark patterns, and declining must be as easy as
  accepting.
- The prompt's outcome calls `grant` per purpose with the policy version;
  declining calls nothing.
- A settings screen shows `consent.status` and offers `withdraw`.
- If the product's policy changes, the new policy version must trigger a
  new prompt; a grant under an old version does not carry over silently.

If the product's owner states a legal basis instead, use
`ConsentPolicy.assumed` with the basis string they give you, and put that
string in the code exactly as given. Do not choose a basis yourself.

## 11. Verifying the integration

1. Run the product against a development environment of the server.
2. Subscribe to `insights.diagnostics` and log it during development.
3. Decline consent, use the product, and confirm the dashboards stay
   empty and no requests leave the client.
4. Grant consent, perform each tracked action once, then open Grafana:
   event segmentation shows the events within seconds, people shows the
   identified user with the profile properties, crashes shows a recorded
   error, and issue detail shows its breadcrumbs.
5. Kill the app mid-flow and relaunch: queued items from before the kill
   arrive. On Flutter web this needs the wasm assets.
6. Read the diagnostics: a rejected item names the malformed property or
   event; a not-consented item means a call happened before consent, which
   is a bug in the product's flow; a dropped people call means it ran
   before `identify`.

## 12. Pitfalls

- Granting consent in code so the dashboards light up. That is a
  compliance failure, not a shortcut.
- Passing an email or a name as the user id.
- Tracking on every render, scroll or frame.
- Building a global mutable context. Use `with` and pass the child.
- Forgetting `flush` before a backend process exits; the mobile and
  browser SDKs persist their queue, the Haskell one does not.
- Reusing a device id across users on shared devices; call `reset` on logout.
- Calling `people` before `identify`.
- Wrapping SDK calls in `try` or in your own service class.
- Changing an event's name or property keys on one platform only.

## 13. Done checklist

You are finished only when every line holds.

- [ ] The URL, key, policy version, in-app packages, consent approach and
      user id source came from the product's owner, not from you.
- [ ] `Insights` is created exactly once, with a `ConsentPolicy`.
- [ ] No recording call runs before consent is decided; the prompt or the
      stated basis is wired.
- [ ] Every event name is `snake_case` past tense and identical across the
      product's platforms.
- [ ] No property, key or log line contains personal data.
- [ ] `identify` runs on login and session restore; `reset` on logout.
- [ ] Screens are tracked through the observer or route hook, not by hand.
- [ ] Handled failures that matter use `attempt` or `recordError`.
- [ ] Flows that are timed use `span`.
- [ ] A test with the recording transport asserts the most important
      events.
- [ ] A Flutter product's build or CI uploads its symbols for every
      release build, with the upload key read from a secret.
- [ ] The verification steps in section 11 were run and the dashboards
      showed the data.
- [ ] The diagnostics stream is logged in development and quiet after the
      verification run.
