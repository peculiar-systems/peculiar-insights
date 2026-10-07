---
title: TypeScript
section: SDKs
order: 5
---

# TypeScript

One package, `peculiar-insights`, under `sdk/ts` in the repository, with two entry points. `peculiar-insights/browser` speaks gRPC-Web and keeps its queue in IndexedDB. `peculiar-insights/node` speaks native gRPC and keeps its queue in a directory. Both share one core: the same `Insights`, the same `Tracker`, the same consent machine.

## Installation

Add the package from this repository and import the entry point for the runtime.

```json
{
  "dependencies": {
    "peculiar-insights": "github:peculiar-systems/peculiar-insights#main&path:sdk/ts"
  }
}
```

```ts
import { createInsights } from "peculiar-insights/browser";
import { createInsights } from "peculiar-insights/node";
```

The package is ESM, ships its declarations, and its generated protobuf code is built from the repository's contract.

## Start

`createInsights` returns an `Insights`. Create one at startup and keep it.

```ts
const insights = await createInsights({
  url: "https://insights.example.org",
  key: ingestKey,
  app: { version: APP_VERSION, build: APP_BUILD },
  consent: ConsentPolicy.ask(),
});
```

Browser options:

| Option                       | Type                 | Default           | Meaning                                                              |
| ---------------------------- | -------------------- | ----------------- | -------------------------------------------------------------------- |
| `url`                        | `string`             | required          | The server, reached over gRPC-Web.                                   |
| `key`                        | `string`             | required          | The write-only ingest key for this environment.                      |
| `app`                        | `{ version, build }` | required          | Injected at build time; a bundle cannot know its own version.        |
| `consent`                    | `ConsentPolicy`      | required          | `ConsentPolicy.ask(...)` or `ConsentPolicy.assumed(...)`.            |
| `debug`                      | `boolean`            | `undefined`       | When true, misuse throws instead of being dropped with a diagnostic. |
| `ignoreGlobalPrivacyControl` | `boolean`            | `false`           | Do not treat the Global Privacy Control signal as a denial.          |
| `captureErrors`              | `boolean`            | `true`            | Install the `error` and `unhandledrejection` listeners.              |
| `scrub`                      | `RegExp[]`           | `undefined`       | Enable redaction with the built-in patterns plus these.              |
| `flushIntervalMs`            | `number`             | `10000`           | How often the queue is sent.                                         |
| `batchSize`                  | `number`             | `100`             | Items per publish call; reaching it triggers a send.                 |
| `transport`                  | `Transport`          | gRPC-Web to `url` | A Connect transport, for tests.                                      |
| `storage`                    | `Storage`            | IndexedDB         | Where the queue and identity persist, for tests.                     |

Node options:

| Option            | Type                 | Default                          | Meaning                                                                                   |
| ----------------- | -------------------- | -------------------------------- | ----------------------------------------------------------------------------------------- |
| `url`             | `string`             | required                         | The server, reached over native gRPC.                                                     |
| `key`             | `string`             | required                         | The ingest key, read from the environment or a file.                                      |
| `app`             | `{ version, build }` | required                         | The service's version and build.                                                          |
| `consent`         | `ConsentPolicy`      | required                         | Usually `ConsentPolicy.assumed(...)` for the service's own telemetry.                     |
| `stateDirectory`  | `string`             | required                         | A directory the process can write; the queue and identity live there.                     |
| `debug`           | `boolean`            | `NODE_ENV !== "production"`      | When true, misuse throws instead of being dropped with a diagnostic.                      |
| `captureErrors`   | `boolean`            | `true`                           | Install the `uncaughtException` and `unhandledRejection` handlers.                        |
| `exitOnUncaught`  | `boolean`            | `true`                           | After recording and flushing an uncaught exception, exit with status 1.                   |
| `scrub`           | `RegExp[]`           | `undefined`                      | Enable redaction with the built-in patterns plus these.                                   |
| `flushIntervalMs` | `number`             | `10000`                          | How often the queue is sent. The timer is unreferenced and never keeps the process alive. |
| `batchSize`       | `number`             | `100`                            | Items per publish call.                                                                   |
| `transport`       | `Transport`          | gRPC to `url`                    | A Connect transport, for tests.                                                           |
| `storage`         | `Storage`            | file storage in `stateDirectory` | For tests.                                                                                |

Both entry points also re-export `Insights.create(options)` for a fully custom assembly with your own `environment`, `sessionStore`, `bufferLimit`, `logLimit`, `now`, `random`, `wait` and `schedule`.

## Consent

Nothing is persisted and no connection is opened before a purpose is granted. The two purposes are `"analytics"` for events, identities, sessions and profiles, and `"diagnostics"` for errors and log lines.

- `ConsentPolicy.ask({ store })` leaves purposes undecided until the product decides. The optional `store` is a `ConsentStore` with `load` and `save`, for keeping the decision where the product keeps its settings; without it the decision persists in the SDK's own storage. Items recorded before a decision wait in a bounded in-memory buffer under a device id that exists only in memory; a grant persists the device id and moves the buffer to the queue, a withdrawal discards it.
- `ConsentPolicy.assumed({ analytics, diagnostics })` grants each purpose given a basis at start unless a decision is already stored. The basis becomes the policy version in the ledger.

The product's banner talks to `insights.consent`:

```ts
await insights.consent.grant("analytics", "2026-01");
await insights.consent.withdraw("analytics");
const current = insights.consent.status();
```

`status()` returns a `Consent`, a partial record from purpose to `{ state: "granted" | "withdrawn", policyVersion }`. Withdrawing a granted purpose removes its queued items, sends one withdrawal record, and once nothing is granted forgets the device and user ids. A withdrawal that follows no grant sends nothing. In the browser, Global Privacy Control counts as a withdrawal of both purposes unless `ignoreGlobalPrivacyControl` is set.

## The tracker

`insights.tracker` is the device-bound tracker. `with` derives an immutable child whose properties fold into everything it records, the child's winning over the parent's.

```ts
const checkout = insights.tracker.with({ screen: "checkout" });
```

| Call                                    | What it does                                                                                                                                                                             |
| --------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `with(properties)`                      | A child tracker carrying the properties, which become event properties and error custom keys.                                                                                            |
| `scope`                                 | The properties the tracker carries.                                                                                                                                                      |
| `userId`                                | The user the tracker is bound to, if any.                                                                                                                                                |
| `track(name, properties?)`              | Record an event. An empty name is misuse.                                                                                                                                                |
| `identify(UserId)`                      | Link the device to a user; returns the tracker to continue with. On a subject tracker it returns a new tracker bound to that user.                                                       |
| `reset()`                               | Forget the user and mint a new device id and session. Device tracker only; on a subject tracker it is misuse.                                                                            |
| `people.set(properties)`                | Merge profile properties. Needs an identified user or it is misuse.                                                                                                                      |
| `people.setOnce(properties)`            | Set profile properties that are not yet set.                                                                                                                                             |
| `people.unset(keys)`                    | Remove profile properties.                                                                                                                                                               |
| `recordError(error, { fatal, thread })` | Record any thrown value: the type and message are described, the V8 or Firefox stack parsed into frames, the tracker's properties become custom keys, the recent log lines are attached. |
| `attempt(action)`                       | Run a sync or async action; on failure record a non-fatal error and rethrow. Returns what the action returns.                                                                            |
| `log(message, level?)`                  | Add a breadcrumb line for the next error. Levels `"debug"`, `"info"`, `"warning"`, `"error"`.                                                                                            |
| `span(name)`                            | Start a timer. `end(properties?)` tracks `name` with `duration_ms` added.                                                                                                                |

Identifiers are branded strings with constructors: `UserId(id)`, `DeviceId(id)`, `SessionId(id)`. Each throws on an empty string, so an empty id cannot reach the server.

## Subjects on a backend

A Node service derives a tracker per request with `insights.subject(ids, consent)`, where `ids` is `{ deviceId, userId?, sessionId }` and `consent` is what the backend holds for that user. `grantedConsent({ analytics, diagnostics })` builds a `Consent` from the policy versions the backend stores. Items whose purpose the consent does not permit are dropped, never buffered.

```ts
const tracker = insights.subject(
  {
    deviceId: DeviceId(request.device),
    sessionId: SessionId(request.session),
    userId: UserId(request.user),
  },
  grantedConsent({ analytics: "2026-01" }),
);
```

`insights.tracker` remains the service's own subject for startup, jobs and crashes.

## Values

`Properties` is an object of `string`, `number`, `boolean`, `bigint`, `Date`, arrays and nested objects of the same. The type rejects anything else at compile time; safe integers travel as `int64`, other numbers as doubles, `Date` as a timestamp. Recording calls never throw in release. Misuse, meaning an empty event name, a people call without a user, `reset` on a subject tracker, or `erase` before any grant, throws when `debug` is true and is otherwise dropped with a diagnostic.

## Diagnostics

`insights.diagnostics(listener)` subscribes and returns the unsubscribe function.

| Kind                 | Fields                                                  | When                                                                                                                         |
| -------------------- | ------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| `"rejected"`         | `id`, `outcome: "invalid" \| "not-consented"`, `reason` | The server refused an item.                                                                                                  |
| `"transport-failed"` | `code`, `message`, `willRetry`                          | A call failed. Retryable codes back off exponentially and the item stays queued.                                             |
| `"dropped"`          | `cause`, `detail`                                       | Something was not recorded. Causes: `"no-user"`, `"empty-name"`, `"no-device"`, `"not-device"`, `"queue-full"`, `"storage"`. |

When the server rate limits a key or a peer, the call fails with `ResourceExhausted` and the batch stays in the queue, so nothing is dropped. The SDK waits for the delay the server asks for, at most five minutes, and sends the batch again; when the server names no delay it falls back to the exponential backoff. The diagnostic for it arrives with `willRetry: true`. In Node, the handler for an uncaught exception waits at most five seconds for delivery before the process exits; the report is on disk by then and the next process sends it.

## Platform capture

In the browser, `createInsights` records `error` events as fatal and `unhandledrejection` as non-fatal, and flushes on `pagehide`. Opt in to `trackRoutes(insights)` for `screen_viewed` with the `path` on every `pushState`, `replaceState` and `popstate`, and to `trackVisibility(insights)` for `app_backgrounded` and `app_foregrounded` with a flush on hide. Each returns a function that removes its listeners.

In Node, `uncaughtException` is recorded as fatal, flushed, and followed by `process.exit(1)` unless `exitOnUncaught` is false; `unhandledRejection` is recorded as non-fatal. Flush on `SIGTERM` yourself.

## Storage

The browser persists the queue, identity and consent in IndexedDB and the session in `localStorage`, every access wrapped so a private window or blocked storage degrades to memory. Node persists to a file in `stateDirectory` with an atomic rename and keeps the session in memory. `memoryStorage()` from the core exists for tests.

## Testing

`recordingTransport()` returns a `Recording`: a Connect transport that accepts everything, plus `published`, `consents`, `erasures`, and readers `events()` giving `{ name, properties, userId }` with plain values, and `errors()` giving the crash reports.

```ts
const recording = recordingTransport();
const insights = await createInsights({
  url: "https://insights.test",
  key: "test",
  app: { version: "0", build: "0" },
  consent: ConsentPolicy.assumed({ analytics: "test" }),
  transport: recording.transport,
  storage: memoryStorage(),
});
await insights.tracker.track("order_placed", { total: 42.5 });
await insights.flush();
assert.equal(recording.events()[0]?.name, "order_placed");
```

Close a client with `insights.dispose()`; it stops the flush timer.

## Example: browser

`sdk/ts/examples/browser.ts`

```ts
import { ConsentPolicy, createInsights, trackRoutes, UserId } from "../src/browser/index.ts";

const insights = await createInsights({
  url: "https://insights.example.org",
  key: "replace-with-the-ingest-key",
  app: { version: "1.0.0", build: "20260101120000" },
  consent: ConsentPolicy.ask(),
});

insights.diagnostics((diagnostic) => {
  console.warn("insights", diagnostic);
});

trackRoutes(insights);

export const acceptAll = async (): Promise<void> => {
  await insights.consent.grant("analytics", "2026-01");
  await insights.consent.grant("diagnostics", "2026-01");
};

export const acceptCrashesOnly = (): Promise<void> =>
  insights.consent.grant("diagnostics", "2026-01");

export const onLogin = async (id: string, plan: string): Promise<void> => {
  const tracker = await insights.tracker.identify(UserId(id));
  await tracker.people.set({ plan });
};

const checkout = insights.tracker.with({ screen: "checkout" });

export const onCheckoutOpened = (total: number, items: number): Promise<void> =>
  checkout.track("checkout_opened", { total, items });

export const pay = (charge: () => Promise<void>): Promise<void> => {
  const span = checkout.span("payment_completed");
  return checkout.attempt(charge).then(() => span.end());
};

export const onLogout = (): Promise<void> => insights.tracker.reset();

export const forgetMe = (): Promise<void> => insights.erase();
```

## Example: Node

`sdk/ts/examples/node.ts`

```ts
import {
  ConsentPolicy,
  createInsights,
  DeviceId,
  grantedConsent,
  SessionId,
  UserId,
  type Consent,
} from "../src/node/index.ts";

const insights = await createInsights({
  url: "https://insights.example.org",
  key: process.env["PECULIAR_INSIGHTS_KEY"] ?? "",
  app: { version: "1.0.0", build: "20260101120000" },
  stateDirectory: "/var/lib/shop-api/insights",
  consent: ConsentPolicy.assumed({
    analytics: "service-telemetry",
    diagnostics: "service-telemetry",
  }),
});

insights.diagnostics((diagnostic) => {
  console.warn("insights", diagnostic);
});

await insights.tracker.track("service_started", { runtime: process.version });

type Request = {
  readonly device: string;
  readonly session: string;
  readonly user?: string;
  readonly consentVersion?: string;
};

const consentOf = (request: Request): Consent =>
  request.consentVersion === undefined ? {} : grantedConsent({ analytics: request.consentVersion });

export const onOrderPlaced = async (request: Request, total: number): Promise<void> => {
  const tracker = insights.subject(
    {
      deviceId: DeviceId(request.device),
      sessionId: SessionId(request.session),
      ...(request.user === undefined ? {} : { userId: UserId(request.user) }),
    },
    consentOf(request),
  );
  await tracker.with({ channel: "api" }).track("order_placed", { total });
};

export const runJob = (name: string, job: () => Promise<void>): Promise<void> => {
  const span = insights.tracker.with({ job: name }).span("job_finished");
  return insights.tracker.attempt(job).then(() => span.end());
};

process.on("SIGTERM", () => {
  insights.flush().finally(() => {
    process.exit(0);
  });
});
```
