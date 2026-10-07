---
title: Flutter
section: SDKs
order: 4
---

# Flutter

Two packages under `sdk/dart` in the repository. `peculiar_insights` is pure Dart: the client, the queue, consent, the tracker. `peculiar_insights_flutter` is the plugin: it fills the platform context, installs error capture, wires sessions to the app lifecycle, and ships the Apple privacy manifest. A Flutter app depends on both; a Dart server or CLI depends on the first alone.

## Installation

Add the packages as path or git dependencies on this repository.

```yaml
dependencies:
  peculiar_insights:
    git:
      url: https://github.com/peculiar-systems/peculiar-insights
      path: sdk/dart/peculiar_insights
  peculiar_insights_flutter:
    git:
      url: https://github.com/peculiar-systems/peculiar-insights
      path: sdk/dart/peculiar_insights_flutter
```

The plugin re-exports the whole pure package, so one import covers everything:

```dart
import "package:peculiar_insights_flutter/peculiar_insights_flutter.dart";
```

## Start

In `main`, before `runApp`. The result is an `Insights`; keep it for the app's lifetime and pass it down.

```dart
final insights = await FlutterInsights.start(
  url: Uri.parse("https://insights.example.org"),
  key: ingestKey,
  consent: const ConsentPolicy.ask(),
);
```

`FlutterInsights.start` reads the app version and build from the package, fills the platform context, opens the durable queue, installs error capture and wires the app lifecycle.

| Option              | Type               | Default             | Meaning                                                                                         |
| ------------------- | ------------------ | ------------------- | ----------------------------------------------------------------------------------------------- |
| `url`               | `Uri`              | required            | The server. Native platforms use gRPC; the web uses gRPC-Web on the same URL.                   |
| `key`               | `String`           | required            | The write-only ingest key for this environment.                                                 |
| `consent`           | `ConsentPolicy`    | required            | `ConsentPolicy.ask()` or `ConsentPolicy.assumed(...)`.                                          |
| `options`           | `InsightsOptions`  | `InsightsOptions()` | Tuning, see below. `sdkName`, `inAppPackages` and `privacyControlSignal` are set by the plugin. |
| `inAppPackages`     | `Iterable<String>` | `[]`                | Package names whose stack frames count as in-app for crash grouping.                            |
| `trackAppLifecycle` | `bool`             | `false`             | Track `app_backgrounded` and `app_foregrounded` on lifecycle changes.                           |
| `sqlite3Wasm`       | `Uri?`             | `null`              | On the web, the URL of `sqlite3.wasm` served by the app.                                        |
| `driftWorker`       | `Uri?`             | `null`              | On the web, the URL of `drift_worker.js` served by the app.                                     |

`InsightsOptions` tunes the client:

| Option                 | Type            | Default    | Meaning                                                                                                                                                                     |
| ---------------------- | --------------- | ---------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `sdkName`              | `String`        | `"dart"`   | Reported in the context; the plugin sets `"flutter"`.                                                                                                                       |
| `flushInterval`        | `Duration`      | 10 seconds | How often the queue is sent.                                                                                                                                                |
| `batchSize`            | `int`           | `100`      | Items per publish call.                                                                                                                                                     |
| `bufferLimit`          | `int`           | `500`      | Items held in memory per purpose before a consent decision.                                                                                                                 |
| `sessionTimeout`       | `Duration`      | 30 minutes | Inactivity after which a new session starts.                                                                                                                                |
| `callTimeout`          | `Duration`      | 20 seconds | Deadline of every call to the server.                                                                                                                                       |
| `logLimit`             | `int`           | `64`       | Breadcrumb lines kept for the next error.                                                                                                                                   |
| `inAppPackages`        | `IList<String>` | `[]`       | As above; the plugin fills it from its own parameter.                                                                                                                       |
| `privacyControlSignal` | `bool`          | `false`    | Treat the browser's Global Privacy Control as a denial; the plugin sets it on the web.                                                                                      |
| `scrubber`             | `Scrubber?`     | `null`     | Opt-in redaction of messages, stack text, log lines and string properties. `Scrubber.standard()` covers emails, card numbers and phone numbers, and takes `extra` patterns. |

Pure Dart calls `Insights.start` directly. It takes the same `url`, `key`, `consent` and `options`, plus `app: AppInfo(version:, build:)`, a `storage` (`MemoryStorage()` or `DriftStorage.native(path)`), an optional `platform: PlatformInfo(...)`, and for tests an optional `transport`, `now` and `newId`.

## Consent

Nothing is persisted and no connection is opened before a purpose is granted. Two purposes exist: `Purpose.analytics` for events, identities, sessions and profiles, and `Purpose.diagnostics` for errors and log lines.

- `ConsentPolicy.ask()` leaves every purpose undecided until the product's own prompt decides. Items recorded meanwhile wait in a bounded in-memory buffer, up to `bufferLimit` per purpose, under a device id that exists only in memory. A grant persists the device id, records the consent, moves the buffer to the durable queue and flushes. A withdrawal discards the buffer for that purpose.
- `ConsentPolicy.assumed(analytics: basis, diagnostics: basis)` grants each purpose given a basis at start, unless a decision is already stored. The basis string is recorded as the policy version, so the ledger shows why the grant exists.

The product's prompt talks to `insights.consent`:

```dart
await insights.consent.grant(Purpose.analytics, policyVersion: "2026-01");
await insights.consent.withdraw(Purpose.analytics);
final current = insights.consent.status;
```

`status` is a `Consent` with `permits(purpose)`, `anyGranted` and `anyDecided`. Withdrawing a purpose that was granted removes its queued items, sends one withdrawal record, and once nothing is granted forgets the device id and user id. A withdrawal that follows no grant sends nothing. On the web, Global Privacy Control counts as a withdrawal of both purposes when nothing has been decided yet.

## The tracker

`insights.tracker` is the device-bound tracker. It is an immutable value; `with_` derives a child whose properties fold into everything it records, and a child's properties win over the parent's.

```dart
final checkout = insights.tracker.with_({"screen": "checkout"});
```

| Call                                              | What it does                                                                                                                                        |
| ------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| `with_(properties)`                               | A child tracker carrying the properties. They become event properties and error custom keys.                                                        |
| `track(name, [properties])`                       | Record an event.                                                                                                                                    |
| `identify(UserId)`                                | Link the device to a user. Earlier anonymous events of the device are linked by the server.                                                         |
| `reset()`                                         | Forget the user, mint a new device id and session. Device tracker only; on a subject tracker it is dropped with a diagnostic.                       |
| `people.set(properties)`                          | Merge profile properties. Needs an identified user or it is dropped with a diagnostic.                                                              |
| `people.setOnce(properties)`                      | Set profile properties that are not yet set.                                                                                                        |
| `people.unset(keys)`                              | Remove profile properties.                                                                                                                          |
| `recordError(error, stackTrace, {fatal, thread})` | Record an error with parsed frames, the raw stack, the tracker's properties as custom keys and the recent log lines. A fatal error flushes at once. |
| `attempt(action)`                                 | Run a sync or async action; on failure record a non-fatal error and rethrow.                                                                        |
| `log(message, {level})`                           | Add a breadcrumb line for the next error. `LogLevel.debug`, `info`, `warning`, `error`.                                                             |
| `span(name)`                                      | Start a timer. `span.end([properties])` tracks `name` with `duration_ms` added. Ending twice is dropped with a diagnostic.                          |

Identifiers are extension types: `UserId`, `DeviceId`, `SessionId`, each wrapping a `String`.

## Subjects

A Dart backend derives a tracker per request with `insights.subject(subject, consent)`, passing the identifiers and the consent the backend holds for that user. Items whose purpose the consent does not permit are dropped with a diagnostic, never buffered.

```dart
final request = insights.subject(
  const Subject(
    device: DeviceId("api-node-1"),
    user: UserId("user-123"),
    session: SessionId("request-42"),
  ),
  Consent.none.granted(Purpose.analytics, "2026-01"),
);
```

`Consent.none` is the undecided value; `granted(purpose, policyVersion)` and `withdrawn(purpose)` derive new values.

## Values

Properties are `Map<String, Object?>`. What converts: `String`, `int`, `double`, `bool`, `DateTime`, `List` and `Map<String, Object?>` of the same, and a `Value` you already built. A `null` entry is skipped. Anything else asserts in a debug build and, in release, is dropped with a `Diagnostic.conversionFailed` naming the key and the runtime type. A recording call never throws in release.

## Diagnostics

`insights.diagnostics` is a broadcast `Stream<Diagnostic>`. Subscribe once and log it.

| Variant                       | Fields                         | When                                                                                                                                                                         |
| ----------------------------- | ------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `Diagnostic.rejected`         | `id`, `outcome`, `reason`      | The server refused an item: `OUTCOME_INVALID` or `OUTCOME_NOT_CONSENTED`.                                                                                                    |
| `Diagnostic.transportFailed`  | `code`, `message`, `willRetry` | A call failed. `willRetry` is true for unavailable, unknown, deadline-exceeded and resource-exhausted; the item stays queued.                                                |
| `Diagnostic.dropped`          | `count`, `reason`              | Items were not recorded: the purpose is withdrawn, the subject's consent does not permit it, a people call without a user, `reset` on a subject tracker, a span ended twice. |
| `Diagnostic.conversionFailed` | `key`, `type`                  | A property value could not convert.                                                                                                                                          |

When the server rate limits a key or a peer, the call fails with resource-exhausted and the batch stays in the durable queue, so nothing is dropped. The next attempt waits for the delay the server asks for, at most five minutes, and falls back to the exponential backoff when the server names none. Until then a flush, scheduled or called by hand, sends nothing.

## Platform capture

The plugin installs `FlutterError.onError` (non-fatal, thread named after the library), `PlatformDispatcher.instance.onError` (fatal) and an isolate error listener (fatal, thread `isolate`), each chaining to the handler that was there before. `AppLifecycleListener` pauses and resumes the session on hide and show, and flushes on pause.

On Android and iOS the plugin also captures native crashes. On Android it installs a handler for uncaught JVM exceptions and handlers for the fatal signals SIGSEGV, SIGBUS, SIGILL, SIGFPE, SIGABRT and SIGTRAP, including those raised in NDK code; on iOS a handler for uncaught Objective-C exceptions and handlers for the same signals, which also catch Swift traps. Each chains to the handler that was there before, so the system crash reporter and other libraries still see the crash. A crash is written to disk as a fatal report: the exception type (the JVM exception class, the exception name or the signal name), message, the crashing thread, its frames with instruction addresses and binary images, and the version and build of the app that crashed. On the next launch `FlutterInsights.start` sends each waiting report as a fatal crash report and deletes its file. Other targets capture what Dart reports.

Native capture follows the diagnostics purpose. A report is written only while diagnostics is granted: before a decision, and after diagnostics is withdrawn, a native crash is lost, as a Dart fatal crash is. Withdrawing diagnostics or calling `erase()` deletes reports still waiting on disk.

Stack traces of obfuscated or split-debug-info builds are parsed into frames carrying the build id and each frame's address, and web traces keep script URL, line and column, so the server can symbolicate them once the build uploads its symbols, as [Uploading symbols](/docs/sdks/symbols) describes.

Opt-in instrumentation, one line each:

- `InsightsNavigatorObserver(insights)` in `navigatorObservers` tracks `screen_viewed` with the route's `settings.name` as `screen` on push, pop and replace.
- `trackAppLifecycle: true` on `start` tracks `app_backgrounded` and `app_foregrounded`.

## Storage

On iOS, Android and desktop the queue is a drift database at `peculiar_insights.sqlite` in the application support directory. On the web the queue lives in a drift database on wasm SQLite, which needs `sqlite3.wasm` and `drift_worker.js` served by the app and passed as `sqlite3Wasm` and `driftWorker`; without them the SDK falls back to `MemoryStorage` and the queue is lost on reload. Pure Dart chooses its own `Storage`: `MemoryStorage()`, `DriftStorage.native(path)`, `DriftStorage.executor(...)` or `DriftStorage.web(...)`.

## Testing

`RecordingTransport` accepts everything and keeps it. Start `Insights` with `transport: RecordingTransport()` and `storage: MemoryStorage()`, then read `published`, `consents`, `erasures`, `items`, `events`, `crashes` or `eventNames`.

```dart
final recording = RecordingTransport();
final insights = await Insights.start(
  url: Uri.parse("https://insights.test"),
  key: "test",
  consent: const ConsentPolicy.assumed(analytics: "test"),
  app: const AppInfo(version: "0", build: "0"),
  storage: MemoryStorage(),
  transport: recording,
);
await insights.tracker.track("order_placed");
await insights.flush();
expect(recording.eventNames, contains("order_placed"));
```

## Example: Flutter

`sdk/dart/peculiar_insights_flutter/example/main.dart`

```dart
import "dart:async";

import "package:flutter/material.dart";
import "package:peculiar_insights_flutter/peculiar_insights_flutter.dart";

Future<void> main() async {
  final insights = await FlutterInsights.start(
    url: Uri.parse("https://insights.example.org"),
    key: "replace-with-the-ingest-key",
    consent: const ConsentPolicy.ask(),
    inAppPackages: const ["shop"],
    trackAppLifecycle: true,
  );
  runApp(ShopApp(insights: insights));
}

final class ShopApp extends StatelessWidget {
  const ShopApp({required this.insights, super.key});

  final Insights insights;

  @override
  Widget build(BuildContext context) => MaterialApp(
    navigatorObservers: [InsightsNavigatorObserver(insights)],
    home: ConsentGate(insights: insights),
  );
}

final class ConsentGate extends StatelessWidget {
  const ConsentGate({required this.insights, super.key});

  final Insights insights;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Help us improve the app?"),
          FilledButton(
            onPressed: () => unawaited(_accept()),
            child: const Text("Yes, share usage and crash data"),
          ),
          TextButton(
            onPressed: () => unawaited(_acceptCrashesOnly()),
            child: const Text("Only crash reports"),
          ),
          FilledButton.tonal(
            onPressed: () => unawaited(_checkout()),
            child: const Text("Open checkout"),
          ),
        ],
      ),
    ),
  );

  Future<void> _accept() async {
    await insights.consent.grant(Purpose.analytics, policyVersion: "2026-01");
    await insights.consent.grant(Purpose.diagnostics, policyVersion: "2026-01");
  }

  Future<void> _acceptCrashesOnly() =>
      insights.consent.grant(Purpose.diagnostics, policyVersion: "2026-01");

  Future<void> _checkout() async {
    final checkout = insights.tracker.with_({"screen": "checkout"});
    await checkout.identify(const UserId("user-123"));
    final span = checkout.span("checkout_completed");
    await checkout.attempt(() async {
      await checkout.track("checkout_opened", {"items": 3, "total": 42.5});
    });
    await span.end();
  }
}
```

## Example: pure Dart

`sdk/dart/peculiar_insights/example/main.dart`

```dart
import "dart:io";

import "package:peculiar_insights/peculiar_insights.dart";

Future<void> main() async {
  final insights = await Insights.start(
    url: Uri.parse("https://insights.example.org"),
    key: "replace-with-the-ingest-key",
    consent: const ConsentPolicy.assumed(
      analytics: "service-telemetry",
      diagnostics: "service-telemetry",
    ),
    app: const AppInfo(version: "1.0.0", build: "20260101120000"),
    storage: MemoryStorage(),
  );
  insights.diagnostics.listen(stderr.writeln);

  final request = insights.subject(
    const Subject(
      device: DeviceId("api-node-1"),
      user: UserId("user-123"),
      session: SessionId("request-42"),
    ),
    Consent.none.granted(Purpose.analytics, "2026-01"),
  );
  final checkout = request.with_({"flow": "checkout"});
  await checkout.track("order_placed", {"total": 42.5, "items": 3});
  await checkout.people.set({"plan": "pro"});

  final span = checkout.span("payment");
  await checkout.attempt(() async {
    await span.end({"provider": "card"});
  });

  await insights.flush();
  await insights.close();
}
```
