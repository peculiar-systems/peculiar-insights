# Peculiar Insights: product decisions

Self-hosted product analytics and crash tracking. Haskell backend over gRPC,
PostgreSQL storage, Grafana as the only frontend, SDKs for Flutter, TypeScript
and Haskell. MIT licensed.

## Scope of v1

In: event analytics (segmentation, funnels, retention, people, cohorts),
crash and exception tracking at the language level, Grafana dashboards and
alert rules, declarative deployment on NixOS.

Out until a later phase: performance monitoring, groups, feature flags and
experiments, event schema registry, user flows, geo lookup, sampling.

## Architecture

- Monorepo: `proto/` is the contract, `backend/` is Haskell split into a pure
  core and an IO shell, `sdk/{dart,ts,haskell}/`, `grafana/` holds
  provisioned dashboards and alert rules, `nixos/module.nix` is the service.
- Proto package `peculiar.insights.v1` under `proto/peculiar/insights/v1/`.
  Services named without a suffix.
- One server binary serves native gRPC, gRPC-Web and Connect on the same
  port through `peculiar-rpc`, which fronts grapesy and derives the server
  record and client record from the proto-lens service types. TLS
  terminates at the host's reverse proxy by default; the module can instead
  hand certificate and key paths to the server, which then serves TLS with
  protocol chosen by ALPN.
- Storage is PostgreSQL. The backend owns the schema through beam, written
  backend-polymorphic and pinned to Postgres at the edge. Migrations are an
  explicit ordered list applied at startup, followed by a probe select of
  every table through the beam schema, so a column the schema names and
  the database lacks fails startup.
  Hand-written SQL exists only in migrations, which also install the
  `reporting` and `admin` schemas.
- Grafana is vanilla: built-in Postgres datasource only, no community
  plugins. It connects as a read-only role limited to the `reporting` schema
  of views and SQL functions. Raw tables are private to the backend. On a
  host where the module provisions both, the role is named `grafana` and
  connects over the local socket with peer authentication, so no database
  password exists anywhere.
- Configuration is declarative. Projects, environments, ingest-key file
  paths, retention and cohorts are NixOS module options, and Grafana edits
  none of them. There are management calls, the `Manage` service of the
  contract, reached from Grafana by Admins: resolving, ignoring and
  reopening an issue from the issue detail dashboard and from each row of
  the crashes list, and erasing the selected person from the people
  dashboard after a confirmation. Dashboard actions call them through
  Grafana's data source proxy as Connect unary with the proto3 JSON
  mapping, the only service that accepts JSON; every other service takes
  binary protobuf only. The server admits a call only with the ID token
  Grafana signs and forwards for the signed-in user, verified against
  Grafana's signing keys, whose role in the provisioned organisation is
  Admin. The calls wrap the SQL functions of the `admin` schema
  (`triage`, `delete_person`).
- The NixOS module is all-in-one with toggles: it runs the service, creates
  the database and roles, and provisions Grafana's datasource, dashboards
  and alert rules. Postgres and Grafana provisioning can each be disabled
  for hosts that already run them.
- Tests are hedgehog only. `nix flake check` also runs an integration suite
  against an ephemeral Postgres started inside the check.

## Ingest contract

- SDKs deliver at least once. Every event and crash report carries a
  client-generated UUID and the server deduplicates on `(project, id)`, so
  delivery is exactly-once in effect.
- A batch carries `sent_at`. The server computes the clock offset from its
  receive time and corrects each item's client timestamp, storing both the
  corrected time and the original.
- A batch is not atomic. Valid items are accepted and invalid ones are
  rejected with a per-item status, so one bad event never blocks a queue.
- Auth is a write-only ingest key per project and environment, sent as
  metadata. Keys are safe to embed in apps and grant nothing but ingest
  and self-scoped erasure.
- Every batch carries a consent snapshot: the state of each purpose and the
  policy version the user accepted. The server refuses items whose purpose
  is not granted, so a defective SDK cannot store unconsented data.
- Metadata also carries SDK name, SDK version and app build id. The server
  refuses an SDK protocol version it no longer understands with
  `FAILED_PRECONDITION`.
- Limits on batch size, item count, name length, property count and
  nesting depth are enforced at the boundary and returned as
  `INVALID_ARGUMENT` per item.
- Transport failures (`UNAVAILABLE`, `UNKNOWN`) retry with exponential
  backoff. Everything else surfaces to the caller.
- Every environment's key has a budget of items, a token bucket with a
  sustained rate and a burst, and the operator may add one per network
  peer. A call past a budget is refused with `RESOURCE_EXHAUSTED` and
  `x-peculiar-retry-after-ms`, at least a quarter of a second and at most
  five minutes. The SDKs keep what they were sending and retry after that
  delay; being throttled never drops data. The header is ours because the
  transport reserves every name that starts with `grpc-`.

## Analytics model

- An event has a name, client time, device id, optional user id, session
  id, a typed context and a property map. Property values are a proto oneof
  of string, int64, double, bool, timestamp, list and map, stored as jsonb.
- Context is typed, not free-form: SDK name and version, app version and
  build, OS name and version, device model, platform, locale, timezone,
  screen size where applicable.
- Identity follows the Mixpanel simplified ID merge model. A device id is
  minted on first launch. `identify(user_id)` links device to person, the
  server resolves the person at ingest, and earlier anonymous events of
  that device are backfilled to the person in the same transaction.
  `reset()` mints a new device id.
- Person profiles support set, set-once and unset.
- Sessions are owned by the SDK: a new session after 30 minutes of
  inactivity, and on mobile after returning from background past the same
  threshold. The server records session start and end.
- Events are immutable except for person backfill and erasure.
- Retention is per project in days, enforced by dropping monthly
  partitions. Unset means keep forever. No raw IP addresses are stored.
- Cohorts are declared in the module as a name plus predicates over person
  properties and event counts within a window. The backend materializes
  each as a view in `reporting`, and dashboards expose them as a variable.
- Funnels are loosely ordered with a conversion window, both driven by
  dashboard variables. Retention is unbounded N-day retention with a birth
  event and a return event as variables. Both live as SQL functions in
  `reporting`, installed by migrations and covered by the integration suite.

## Crash model

- A report carries exception type, message, raw frames, fatal flag, thread
  name where known, build id and version, typed context, custom keys and
  recent log lines. Frames carry instruction addresses and binary images
  where the platform has them.
- Flutter crash reports are symbolicated on the server from the symbols the
  product's build uploads with the flake's `peculiar-insights-upload-symbols`
  app and a per-project upload key: Dart symbols, web source maps, R8
  mappings, NDK symbols and dSYMs. A later upload for a build adds the kinds
  it carries and replaces those the build had; an upload over the module's
  cap, 1 GiB unless set, is refused. Reading the formats is wrapped in a Rust
  adapter over Sentry's libraries, behind gRPC on a Unix socket.
- Raw frames are kept beside the symbolicated ones; grouping uses the
  symbolicated frames. A report arriving before its symbols is grouped raw
  and alerts then; when the symbols arrive its build's reports are
  regrouped. An issue the regrouping creates takes the shared resolved or
  ignored state of the issues its reports left, or starts open, and raises
  no new-issue alert; an existing issue keeps its state; an emptied issue is
  deleted.
- A build's symbols are kept while any report of the build is retained;
  symbols that never received a report go once the project's longest
  retention passes.
- Breadcrumbs are not duplicated. A report carries its session id, and the
  preceding events of that session are fetched by query.
- Grouping fingerprints on exception type plus normalized top in-app frames.
  Issues are open, resolved or ignored. A resolved issue that reappears on
  a newer build is reopened and marked regressed.
- Crash-free users and crash-free sessions derive from sessions.
- Fatal crashes persist to disk and are sent on next launch.
- Capture points: Flutter uses `FlutterError.onError`,
  `PlatformDispatcher.onError` and isolate errors, and on Android and iOS
  native handlers for uncaught JVM and Objective-C exceptions and fatal
  signals, written to disk only while diagnostics is granted and sent on
  next launch; browser listens for
  `error` and `unhandledrejection`; Node uses process-level
  uncaught exception and rejection handlers; Haskell wraps at the caller's
  loop boundary with the call stack it has.

## SDKs

- Targets: TypeScript in the browser (gRPC-Web via connect-web, IndexedDB
  queue) and in Node (native gRPC, file-backed queue); Flutter on mobile,
  desktop and web (grpc-dart, switching to `GrpcWebClientChannel` on web);
  Haskell for backend services (native gRPC).
- Shared surface: `track`, `identify`, `reset`, `people.set`,
  `people.setOnce`, `people.unset`, `recordError`, `attempt`, `log`,
  `span`, `flush`, `close`, `consent.grant`, `consent.withdraw`,
  `consent.status`, `erase`, `diagnostics`. Sessions and context are
  automatic; the Developer-facing API section below is the full shape.
- The Haskell SDK takes a consent value per subject on every call, since a
  server has no user in front of it to ask.
- Generated proto messages are the model. No DTO layer.

## Compliance

- Two consent purposes. Analytics covers events, profiles and sessions.
  Diagnostics covers crash reports and log lines. Each is granted or
  withdrawn independently, and an app may default either one as its
  jurisdiction allows.
- Before a purpose is decided, the SDK persists nothing and opens no
  connection. Items for that purpose accumulate in a bounded in-memory
  buffer with a device id that exists only in memory. A grant persists the
  device id and flushes the buffer. A denial or process exit discards both.
  A fatal crash before a diagnostics decision is therefore lost, because
  writing it to disk would be storage without consent.
- Consent is a record, not an event. Grants and withdrawals are stored with
  purpose, policy version and time as proof of consent. A denial that
  follows no grant is never sent.
- Withdrawing a purpose stops capture for it, drops that purpose's queued
  items and sends one withdrawal record; once no purpose remains granted
  the device id and user id are dropped too. Withdrawal and erasure are
  distinct. The Haskell SDK holds to the same rule for what waits in its
  queue, its retries and its spool: a withdrawal drops that person's
  waiting items of that purpose, an erasure those of both, before either
  is sent.
- `erase()` sends a tombstone for the current device id and, when
  identified, the linked person. The server erases both and records the
  request. The scope is what the device can prove it is, so an ingest key
  cannot erase arbitrary users. A Grafana Admin erases any person from the
  people dashboard.
- The browser SDK treats Global Privacy Control as a denial of both
  purposes unless the app overrides it explicitly.
- A client-side scrubber, opt-in, redacts emails, phone numbers and card
  numbers from crash messages, log lines and string properties, with
  app-supplied patterns added. A per-project property denylist in the
  NixOS module is the second line.
- Every collected proto field carries a custom option naming its data
  category and purpose. A task generates the data inventory document and
  the Apple privacy manifest from those options, so a field cannot be
  collected without being declared. The Flutter plugin ships the manifest
  in its iOS folder.
- Data residency is solved by self-hosting and documented, not engineered.

## Operating projects

Settled 2026-09-26 after the first hosting discussion.

- **A project is declared where the product is declared.** The module's
  `projects` option merges across NixOS modules, so a product's own module
  sets `services.peculiar-insights.projects.<slug>.environments.<env>`
  and the Insights host lists nothing itself.
- **Keys are generated, not typed.** An environment without `keyFile`
  gets a key generated by the service at first start under its state
  directory, and `services.peculiar-insights.keyFiles."<slug>/<env>"`
  exposes the path so another service on the host loads it as a
  credential. A provided `keyFile` remains the override for keys that
  arrive the other way. Products built elsewhere still receive the key
  through the host's secret channel; the host is the source of truth.
- **Analytics are declared, never written in SQL.** Each environment
  declares `analytics.funnels`, `analytics.retention` and
  `analytics.metrics` beside its cohorts. The server installs a reporting
  view per declaration, and the module generates a Grafana dashboard per
  environment into a folder named after the project. Explore remains for
  one-off questions and defines nothing.

- Analysis is declared, never written. Wherever a declaration names an
  event it may name the property values the event must carry: funnel steps,
  retention births and returns, metrics and cohort conditions. A metric may
  carry a measure, one numeric property aggregated per day as a sum, an
  average, a minimum, a maximum, a median or a high percentile. A view whose
  declaration was removed is dropped at the next start.
- The server exposes its own counters in the Prometheus text format on a
  port apart from the one SDKs reach, off by default.
- `peculiar-insights-server --check` validates a configuration without the
  database or the keys, and the module's check runs it on what the module
  renders, so the module and the server cannot drift apart unnoticed.

## Developer-facing API

Settled 2026-09-26 after the first scaffold shipped. Events stay dynamic:
they are strings with property maps, never declared in a schema, because
what a product measures is too fluid to freeze in a contract. Everything
around them is typed and shaped so that misuse is hard.

- **Two objects, the same in every language.** `Insights` is the process:
  connection, queue, consent policy, lifecycle, diagnostics. One per
  process. `Tracker` is a subject bound to a consent; every recording call
  lives on a tracker. Flutter and the browser get the single device-bound
  tracker from `Insights`; backends derive one per request with
  `insights.subject(subject, consent)`. Node and Haskell share this model.
- **Trackers are immutable values.** `tracker.with(properties)` returns a
  child whose properties fold into every event and error it records. This
  is the only mechanism for super properties, per-screen scope, per-request
  context and custom crash keys; there is no mutable global state.
- **Construction needs a consent policy and nothing else the platform
  knows.** `Insights.start(url, key, consent)` where consent is
  `ConsentPolicy.ask`, wired to the product's prompt and persistence, or
  `ConsentPolicy.assumed(basis)`, whose basis string is recorded as the
  policy version of an automatic grant. App version, build, platform,
  locale and timezone come from the platform; the browser injects version
  and build at build time.
- **Values are the language's own.** Numbers, strings, booleans, dates,
  lists and nested maps convert at the boundary; nothing else is accepted.
  TypeScript rejects other types at compile time. Dart and Haskell convert
  at runtime. Haskell spells properties `["total" =: 42.5]`, a plain list
  with an operator that does not collide with aeson's.
- **A recording call never throws in release.** Problems flow into one
  typed `Diagnostic` stream on `Insights`: rejected item with reason,
  transport failure with retry intent, dropped items with cause, value
  conversion failures. In debug builds the same conditions assert, so
  mistakes surface during development and never in production.
- **Identifiers are newtypes**: `UserId`, `DeviceId`, `SessionId`.
- **Errors.** `recordError(error, stack)` with breadcrumb logs;
  `attempt(action)` runs the action, records a non-fatal error on failure
  and rethrows; automatic capture stays per platform, and Haskell gets a
  loop-boundary wrapper.
- **Profiles** are `people.set`, `people.setOnce` and `people.unset` with
  the same value rules. `increment` is gone; counters are events.
- **Spans.** `tracker.span(name)` returns a handle; `span.end(properties)`
  tracks the event with a `duration_ms` property.
- **Built-in instrumentation is opt-in and one line each**: `screen_viewed`
  from a Flutter navigator observer and a browser route hook, app
  foreground and background events. No autocapture of clicks or inputs.
- **Testing.** Every SDK ships a recording transport so product tests can
  assert what was tracked. In Haskell, `Insights` and `Tracker` are records
  of functions meant to live in the product's `Env` behind `HasInsights`,
  so a fake is a value of the same type.
- **The vocabulary is fixed across languages**: `start`, `tracker`,
  `subject`, `with`, `track`, `identify`, `reset`, `people`, `recordError`,
  `attempt`, `log`, `span`, `flush`, `close`, `consent`, `erase`,
  `diagnostics`.

The transport, the consent state machine, queues, crash capture, the
server and the dashboards are unchanged by this; the wire carries the same
items.

## Dashboards and alerts

Dashboards: overview, event segmentation, funnel, retention, people,
crashes overview, issue detail, consent. Alert rules: new issue,
regression, crash-free rate below threshold, ingest silence per project.
The dashboard JSON under `grafana/dashboards` is the provisioning artifact
Grafana loads and is committed as such; every panel and variable query is
executed against the migrations in an ephemeral PostgreSQL before it lands.

## Transport

The Haskell gRPC package is `peculiar-rpc`, consumed as a flake input. A
service becomes a record with one field per RPC through `deriveService`, so
a missing handler is a missing field and a renamed RPC is a compile error.
Browsers use gRPC-Web; Connect is served as well and may be adopted by a
client later without a server change. The health service ships with the
library and is exposed for the host's probes.
