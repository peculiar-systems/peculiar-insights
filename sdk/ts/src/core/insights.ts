import { create, fromJson, toJson, type JsonValue } from "@bufbuild/protobuf";
import { timestampFromMs } from "@bufbuild/protobuf/wkt";
import { ConnectError, createClient, type Transport } from "@connectrpc/connect";
import { ConsentState } from "../gen/peculiar/insights/v1/common_pb.js";
import {
  IdentifySchema,
  Ingest,
  ItemSchema,
  Outcome,
  PublishRequestSchema,
  RecordConsentRequestSchema,
  RequestErasureRequestSchema,
  SubjectSchema,
  type Item,
  type PublishResponse,
  type Subject,
} from "../gen/peculiar/insights/v1/ingest_pb.js";
import { pauseMs, rateLimited, retryable } from "./backoff.ts";
import { buffered, discarded, drained, emptyBuffer, type Buffer } from "./buffer.ts";
import {
  anyGranted,
  decided,
  granted,
  permits,
  purposeEnum,
  purposeOfItem,
  purposes,
  snapshotOf,
  withdrawn,
  type Consent,
  type Purpose,
} from "./consent.ts";
import { contextOf, type AppInfo, type Environment } from "./context.ts";
import {
  diagnosticsHub,
  type Diagnostic,
  type Diagnostics,
  type DropCause,
} from "./diagnostics.ts";
import type { Breadcrumbs, Engine } from "./engine.ts";
import { newId, UserId } from "./ids.ts";
import type { ConsentPolicy, ConsentStore } from "./policy.ts";
import { nextBatch, type Queued } from "./queue.ts";
import { builtinPatterns, identityScrubber, scrubber, type Scrubber } from "./scrub.ts";
import { advanced, type SessionStore } from "./session.ts";
import { emptyPersisted, withIdentity, type Persisted, type Storage } from "./storage.ts";
import { Tracker, type SubjectIds } from "./tracker.ts";

export type Options = {
  readonly key: string;
  readonly app: AppInfo;
  readonly consent: ConsentPolicy;
  readonly transport: Transport;
  readonly storage: Storage;
  readonly environment: Environment;
  readonly sessionStore: SessionStore;
  readonly debug?: boolean;
  readonly initialConsent?: Consent;
  readonly scrub?: readonly RegExp[];
  readonly flushIntervalMs?: number;
  readonly batchSize?: number;
  readonly bufferLimit?: number;
  readonly logLimit?: number;
  readonly now?: () => number;
  readonly random?: () => number;
  readonly wait?: (ms: number) => Promise<void>;
  readonly schedule?: (run: () => void, ms: number) => () => void;
};

export type ConsentApi = {
  readonly grant: (purpose: Purpose, policyVersion: string) => Promise<void>;
  readonly withdraw: (purpose: Purpose, policyVersion?: string) => Promise<void>;
  readonly status: () => Consent;
};

const protocolHeaders = (key: string): HeadersInit => ({
  authorization: `Bearer ${key}`,
  "x-peculiar-protocol": "1",
});

const defaultWait = (ms: number): Promise<void> =>
  new Promise((resolve) => {
    setTimeout(resolve, ms);
  });

const defaultSchedule = (run: () => void, ms: number): (() => void) => {
  const handle = setTimeout(run, ms);
  return () => {
    clearTimeout(handle);
  };
};

const outcomeDiagnostics = (response: PublishResponse): readonly Diagnostic[] =>
  response.outcomes.flatMap((outcome): readonly Diagnostic[] => {
    if (outcome.outcome === Outcome.INVALID) {
      return [{ kind: "rejected", id: outcome.id, outcome: "invalid", reason: outcome.reason }];
    }
    if (outcome.outcome === Outcome.NOT_CONSENTED) {
      return [
        { kind: "rejected", id: outcome.id, outcome: "not-consented", reason: outcome.reason },
      ];
    }
    return [];
  });

type Mutable = {
  persisted: Persisted;
  transientDeviceId: string | undefined;
  transientUserId: UserId | undefined;
  buffer: Buffer;
  sending: Promise<void> | undefined;
  again: boolean;
  attempt: number;
  cancel: (() => void) | undefined;
  disposed: boolean;
};

export class Insights {
  readonly #options: Options;
  readonly #api: ReturnType<typeof createClient<typeof Ingest>>;
  readonly #scrub: Scrubber;
  readonly #state: Mutable;
  readonly #hub = diagnosticsHub();
  readonly #store: ConsentStore | undefined;
  readonly #crumbs: Breadcrumbs = { lines: [] };
  readonly #device: Tracker;

  private constructor(options: Options, persisted: Persisted) {
    this.#options = options;
    this.#api = createClient(Ingest, options.transport);
    this.#scrub =
      options.scrub === undefined
        ? identityScrubber
        : scrubber([...builtinPatterns, ...options.scrub]);
    this.#store = options.consent.kind === "ask" ? options.consent.store : undefined;
    this.#state = {
      persisted,
      transientDeviceId: undefined,
      transientUserId: undefined,
      buffer: emptyBuffer(options.bufferLimit ?? 500),
      sending: undefined,
      again: false,
      attempt: 0,
      cancel: undefined,
      disposed: false,
    };
    this.#device = new Tracker(this.#engine(), { kind: "device" }, {}, this.#crumbs);
    this.#schedule(options.flushIntervalMs ?? 10_000);
  }

  static async create(options: Options): Promise<Insights> {
    const loaded = await options.storage.load();
    const stored =
      options.consent.kind === "ask" && options.consent.store !== undefined
        ? await options.consent.store.load()
        : undefined;
    const persisted: Persisted = {
      ...(loaded ?? emptyPersisted),
      consent: stored ?? loaded?.consent ?? options.initialConsent ?? {},
    };
    const insights = new Insights(options, persisted);
    if (options.consent.kind === "assumed" && options.initialConsent === undefined) {
      for (const purpose of purposes) {
        const basis = options.consent.basis[purpose];
        if (basis !== undefined && !decided(persisted.consent, purpose)) {
          await insights.#grant(purpose, basis);
        }
      }
    }
    return insights;
  }

  get tracker(): Tracker {
    return this.#device;
  }

  subject(ids: SubjectIds, consent: Consent): Tracker {
    return new Tracker(this.#engine(), { kind: "subject", ids, consent }, {}, { lines: [] });
  }

  get diagnostics(): Diagnostics {
    return this.#hub.subscribe;
  }

  get consent(): ConsentApi {
    return {
      grant: async (purpose, policyVersion) => {
        await this.#grant(purpose, policyVersion);
      },
      withdraw: async (purpose, policyVersion) => {
        await this.#withdraw(purpose, policyVersion);
      },
      status: () => this.#state.persisted.consent,
    };
  }

  get deviceId(): string | undefined {
    return this.#state.persisted.deviceId ?? this.#state.transientDeviceId;
  }

  get userId(): UserId | undefined {
    const stored = this.#state.persisted.userId;
    return stored === undefined ? this.#state.transientUserId : UserId(stored);
  }

  async #reset(): Promise<void> {
    const fresh = newId();
    const keep = anyGranted(this.#state.persisted.consent);
    this.#state.persisted = withIdentity(
      this.#state.persisted,
      keep ? fresh : undefined,
      undefined,
    );
    this.#state.transientDeviceId = keep ? undefined : fresh;
    this.#state.transientUserId = undefined;
    this.#options.sessionStore.save({ id: newId(), lastActivity: this.#now() });
    await this.#persist();
  }

  async flush(): Promise<void> {
    const inFlight = this.#state.sending;
    if (inFlight !== undefined) {
      this.#state.again = true;
      await inFlight;
      return;
    }
    const run = this.#drain().finally(() => {
      this.#state.sending = undefined;
    });
    this.#state.sending = run;
    await run;
  }

  async erase(): Promise<void> {
    const deviceId = this.deviceId;
    if (deviceId === undefined) {
      this.#misuse("no-device", "nothing to erase before a consent grant");
      return;
    }
    const user = this.userId;
    const request = create(RequestErasureRequestSchema, {
      id: newId(),
      time: this.#stamp(),
      deviceId,
      ...(user === undefined ? {} : { userId: user }),
    });
    await this.#withRetries(() =>
      this.#api.requestErasure(request, { headers: protocolHeaders(this.#options.key) }),
    );
    const consent = this.#state.persisted.consent;
    this.#state.persisted = { ...emptyPersisted, consent };
    this.#state.transientDeviceId = undefined;
    this.#state.buffer = emptyBuffer(this.#state.buffer.limit);
    await this.#options.storage.clear();
    await this.#persist();
  }

  dispose(): void {
    this.#state.disposed = true;
    this.#state.cancel?.();
  }

  #engine(): Engine {
    return {
      ingest: (item, consent) => this.#ingest(item, consent),
      deviceSubject: () => this.#subject(),
      deviceUserId: () => this.userId,
      identifyDevice: (user) => this.#identify(user),
      resetDevice: () => this.#reset(),
      stamp: () => this.#stamp(),
      context: () => contextOf(this.#options.environment, this.#options.app),
      scrub: this.#scrub,
      now: () => this.#now(),
      logLimit: this.#options.logLimit ?? 50,
      report: (diagnostic) => {
        this.#hub.emit(diagnostic);
      },
      misuse: (cause, detail) => {
        this.#misuse(cause, detail);
      },
    };
  }

  #misuse(cause: DropCause, detail: string): void {
    if (this.#options.debug === true) {
      throw new Error(`peculiar-insights: ${detail}`);
    }
    this.#hub.emit({ kind: "dropped", cause, detail });
  }

  #background(): void {
    this.flush().catch(() => undefined);
  }

  #now(): number {
    return (this.#options.now ?? Date.now)();
  }

  #stamp() {
    return timestampFromMs(this.#now());
  }

  #deviceId(): string {
    const existing = this.deviceId;
    if (existing !== undefined) {
      return existing;
    }
    const fresh = newId();
    if (anyGranted(this.#state.persisted.consent)) {
      this.#state.persisted = { ...this.#state.persisted, deviceId: fresh };
    } else {
      this.#state.transientDeviceId = fresh;
    }
    return fresh;
  }

  #session(): string {
    const store = this.#options.sessionStore;
    const session = advanced(store.load(), this.#now(), newId);
    store.save(session);
    return session.id;
  }

  #subject(): Subject {
    const user = this.userId;
    return create(SubjectSchema, {
      deviceId: this.#deviceId(),
      sessionId: this.#session(),
      ...(user === undefined ? {} : { userId: user }),
    });
  }

  async #identify(user: UserId): Promise<void> {
    if (permits(this.#state.persisted.consent, "analytics")) {
      this.#state.persisted = { ...this.#state.persisted, userId: user };
      this.#state.transientUserId = undefined;
    } else {
      this.#state.transientUserId = user;
    }
    const identify = create(IdentifySchema, {
      id: newId(),
      time: this.#stamp(),
      deviceId: this.#deviceId(),
      userId: user,
    });
    await this.#ingest(
      create(ItemSchema, { kind: { case: "identify", value: identify } }),
      undefined,
    );
  }

  async #ingest(item: Item, consent: Consent | undefined): Promise<void> {
    const purpose = purposeOfItem(item);
    if (consent !== undefined) {
      if (permits(consent, purpose)) {
        this.#enqueue([{ item: toJson(ItemSchema, item), consent }]);
        await this.#afterEnqueue();
      }
      return;
    }
    const current = this.#state.persisted.consent;
    if (permits(current, purpose)) {
      this.#enqueue([{ item: toJson(ItemSchema, item) }]);
      await this.#afterEnqueue();
      return;
    }
    if (!decided(current, purpose)) {
      this.#state.buffer = buffered(this.#state.buffer, item);
    }
  }

  async #afterEnqueue(): Promise<void> {
    await this.#persist();
    if (this.#state.persisted.items.length >= (this.#options.batchSize ?? 100)) {
      this.#background();
    }
  }

  #enqueue(entries: readonly Queued[]): void {
    this.#state.persisted = {
      ...this.#state.persisted,
      items: [...this.#state.persisted.items, ...entries],
    };
  }

  #consentRecord(purpose: Purpose, state: ConsentState, policyVersion: string): JsonValue {
    const user = this.userId;
    return toJson(
      RecordConsentRequestSchema,
      create(RecordConsentRequestSchema, {
        id: newId(),
        time: this.#stamp(),
        deviceId: this.#deviceId(),
        ...(user === undefined ? {} : { userId: user }),
        purpose: { purpose: purposeEnum(purpose), state, policyVersion },
      }),
    );
  }

  async #grant(purpose: Purpose, policyVersion: string): Promise<void> {
    const consent = granted(this.#state.persisted.consent, purpose, policyVersion);
    const record = this.#consentRecord(purpose, ConsentState.GRANTED, policyVersion);
    const deviceId = this.#deviceId();
    const { taken, rest } = drained(this.#state.buffer, purpose);
    this.#state.buffer = rest;
    const carried = permits(consent, "analytics") ? this.#state.transientUserId : undefined;
    this.#state.persisted = {
      ...this.#state.persisted,
      deviceId,
      consent,
      consents: [...this.#state.persisted.consents, record],
      ...(carried === undefined ? {} : { userId: carried }),
    };
    this.#state.transientDeviceId = undefined;
    if (carried !== undefined) {
      this.#state.transientUserId = undefined;
    }
    this.#enqueue(taken.map((item) => ({ item: toJson(ItemSchema, item) })));
    await this.#saveConsent(consent);
    await this.#persist();
    this.#background();
  }

  async #withdraw(purpose: Purpose, policyVersion?: string): Promise<void> {
    const before = this.#state.persisted.consent;
    const previous = before[purpose];
    const version = policyVersion ?? previous?.policyVersion ?? "";
    const consent = withdrawn(before, purpose, version);
    const withdrawal =
      previous?.state === "granted" && this.deviceId !== undefined
        ? [this.#consentRecord(purpose, ConsentState.WITHDRAWN, version)]
        : [];
    const kept = this.#state.persisted.items.filter(
      (queued) =>
        queued.consent !== undefined ||
        purposeOfItem(fromJson(ItemSchema, queued.item)) !== purpose,
    );
    this.#state.buffer = discarded(this.#state.buffer, purpose);
    const updated: Persisted = {
      ...this.#state.persisted,
      consent,
      items: kept,
      consents: [...this.#state.persisted.consents, ...withdrawal],
    };
    this.#state.persisted = anyGranted(consent)
      ? updated
      : withIdentity(updated, undefined, undefined);
    this.#state.transientDeviceId = undefined;
    if (!anyGranted(consent)) {
      this.#state.transientUserId = undefined;
    }
    await this.#saveConsent(consent);
    await this.#persist();
    this.#background();
  }

  async #saveConsent(consent: Consent): Promise<void> {
    if (this.#store === undefined) {
      return;
    }
    try {
      await this.#store.save(consent);
    } catch (error: unknown) {
      this.#hub.emit({ kind: "dropped", cause: "storage", detail: String(error) });
    }
  }

  async #persist(): Promise<void> {
    try {
      await this.#options.storage.save(this.#state.persisted);
    } catch (error: unknown) {
      this.#hub.emit({ kind: "dropped", cause: "storage", detail: String(error) });
    }
  }

  #schedule(intervalMs: number): void {
    if (this.#state.disposed) {
      return;
    }
    this.#state.cancel = (this.#options.schedule ?? defaultSchedule)(() => {
      this.flush()
        .catch(() => undefined)
        .finally(() => {
          this.#schedule(intervalMs);
        });
    }, intervalMs);
  }

  #takeAgain(): boolean {
    const { again } = this.#state;
    this.#state.again = false;
    return again;
  }

  async #drain(): Promise<void> {
    this.#state.again = false;
    await this.#send();
    if (this.#takeAgain()) {
      await this.#drain();
    }
  }

  async #send(): Promise<void> {
    const headers = protocolHeaders(this.#options.key);
    for (const json of this.#state.persisted.consents) {
      const outcome = await this.#call(() =>
        this.#api.recordConsent(fromJson(RecordConsentRequestSchema, json), { headers }),
      );
      if (outcome === "retry") {
        return;
      }
      this.#state.persisted = {
        ...this.#state.persisted,
        consents: this.#state.persisted.consents.filter((entry) => entry !== json),
      };
      await this.#persist();
    }
    const size = this.#options.batchSize ?? 100;
    while (this.#state.persisted.items.length > 0) {
      const { batch, consent } = nextBatch(this.#state.persisted.items, size);
      const request = create(PublishRequestSchema, {
        sentAt: this.#stamp(),
        consent: snapshotOf(consent ?? this.#state.persisted.consent),
        items: batch.map((queued) => fromJson(ItemSchema, queued.item)),
      });
      const outcome = await this.#call(async () => {
        const response = await this.#api.publish(request, { headers });
        for (const diagnostic of outcomeDiagnostics(response)) {
          this.#hub.emit(diagnostic);
        }
      });
      if (outcome === "retry") {
        return;
      }
      this.#state.persisted = {
        ...this.#state.persisted,
        items: this.#state.persisted.items.slice(batch.length),
      };
      await this.#persist();
    }
  }

  async #call(call: () => Promise<unknown>): Promise<"done" | "retry"> {
    try {
      await call();
      this.#state.attempt = 0;
      return "done";
    } catch (error: unknown) {
      const failure = ConnectError.from(error);
      const willRetry = retryable(failure.code);
      this.#failed(failure, willRetry);
      if (willRetry) {
        const attempt = this.#state.attempt;
        this.#state.attempt = attempt + 1;
        await this.#pause(failure, attempt);
        return "retry";
      }
      return "done";
    }
  }

  async #withRetries(call: () => Promise<unknown>, attempt = 0, spent = 0): Promise<void> {
    try {
      await call();
    } catch (error: unknown) {
      const failure = ConnectError.from(error);
      const limited = rateLimited(failure.code);
      if (!retryable(failure.code) || (!limited && spent >= 5)) {
        throw error;
      }
      this.#failed(failure, true);
      await this.#pause(failure, attempt);
      await this.#withRetries(call, attempt + 1, limited ? spent : spent + 1);
    }
  }

  #failed(failure: ConnectError, willRetry: boolean): void {
    this.#hub.emit({
      kind: "transport-failed",
      code: failure.code,
      message: failure.rawMessage,
      willRetry,
    });
  }

  async #pause(failure: ConnectError, attempt: number): Promise<void> {
    const wait = this.#options.wait ?? defaultWait;
    await wait(pauseMs(failure.metadata, attempt, this.#options.random));
  }
}
