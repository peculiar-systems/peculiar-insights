import { create } from "@bufbuild/protobuf";
import {
  CrashReportSchema,
  EventSchema,
  IdentifySchema,
  ItemSchema,
  LogLevel,
  LogLineSchema,
  ProfileOperationSchema,
  ProfileUpdateSchema,
  SubjectSchema,
  UnsetSchema,
  type ProfileOperation,
  type Subject,
} from "../gen/peculiar/insights/v1/ingest_pb.js";
import type { Consent } from "./consent.ts";
import type { Breadcrumbs, Engine } from "./engine.ts";
import { newId, type DeviceId, type SessionId, type UserId } from "./ids.ts";
import { scrubProperties } from "./scrub.ts";
import { describeError, parseStack } from "./stack.ts";
import { propertiesOf, type Properties } from "./values.ts";

export type Level = "debug" | "info" | "warning" | "error";

export type ErrorOptions = {
  readonly fatal?: boolean;
  readonly thread?: string;
};

export type SubjectIds = {
  readonly deviceId: DeviceId;
  readonly userId?: UserId;
  readonly sessionId: SessionId;
};

export type Span = {
  readonly end: (properties?: Properties) => Promise<void>;
};

export type People = {
  readonly set: (properties: Properties) => Promise<void>;
  readonly setOnce: (properties: Properties) => Promise<void>;
  readonly unset: (keys: readonly string[]) => Promise<void>;
};

export type Identity =
  | { readonly kind: "device" }
  | { readonly kind: "subject"; readonly ids: SubjectIds; readonly consent: Consent };

const levels: Readonly<Record<Level, LogLevel>> = {
  debug: LogLevel.DEBUG,
  info: LogLevel.INFO,
  warning: LogLevel.WARNING,
  error: LogLevel.ERROR,
};

const isPromise = (value: unknown): value is Promise<unknown> =>
  typeof value === "object" &&
  value !== null &&
  "then" in value &&
  typeof value.then === "function";

const operations = (kind: "set" | "setOnce", properties: Properties): readonly ProfileOperation[] =>
  Object.entries(propertiesOf(properties)).map(([key, value]) =>
    create(ProfileOperationSchema, { key, kind: { case: kind, value } }),
  );

export class Tracker {
  readonly #engine: Engine;
  readonly #identity: Identity;
  readonly #scope: Properties;
  readonly #crumbs: Breadcrumbs;

  constructor(engine: Engine, identity: Identity, scope: Properties, crumbs: Breadcrumbs) {
    this.#engine = engine;
    this.#identity = identity;
    this.#scope = scope;
    this.#crumbs = crumbs;
  }

  with(properties: Properties): Tracker {
    return new Tracker(
      this.#engine,
      this.#identity,
      { ...this.#scope, ...properties },
      this.#crumbs,
    );
  }

  get scope(): Properties {
    return this.#scope;
  }

  get userId(): UserId | undefined {
    return this.#identity.kind === "device"
      ? this.#engine.deviceUserId()
      : this.#identity.ids.userId;
  }

  get people(): People {
    return {
      set: (properties) => this.#profile(operations("set", properties)),
      setOnce: (properties) => this.#profile(operations("setOnce", properties)),
      unset: (keys) =>
        this.#profile(
          keys.map((key) =>
            create(ProfileOperationSchema, {
              key,
              kind: { case: "unset", value: create(UnsetSchema) },
            }),
          ),
        ),
    };
  }

  async track(name: string, properties: Properties = {}): Promise<void> {
    if (name.length === 0) {
      this.#engine.misuse("empty-name", "an event needs a name");
      return;
    }
    const event = create(EventSchema, {
      id: newId(),
      time: this.#engine.stamp(),
      subject: this.#subject(),
      context: this.#engine.context(),
      name,
      properties: this.#properties(properties),
    });
    await this.#engine.ingest(
      create(ItemSchema, { kind: { case: "event", value: event } }),
      this.#consent(),
    );
  }

  async identify(userId: UserId): Promise<Tracker> {
    if (this.#identity.kind === "device") {
      await this.#engine.identifyDevice(userId);
      return this;
    }
    const identify = create(IdentifySchema, {
      id: newId(),
      time: this.#engine.stamp(),
      deviceId: this.#identity.ids.deviceId,
      userId,
    });
    await this.#engine.ingest(
      create(ItemSchema, { kind: { case: "identify", value: identify } }),
      this.#identity.consent,
    );
    return new Tracker(
      this.#engine,
      { kind: "subject", ids: { ...this.#identity.ids, userId }, consent: this.#identity.consent },
      this.#scope,
      this.#crumbs,
    );
  }

  async reset(): Promise<void> {
    if (this.#identity.kind === "device") {
      await this.#engine.resetDevice();
      return;
    }
    this.#engine.misuse("not-device", "reset applies to the device tracker only");
  }

  async recordError(error: unknown, options: ErrorOptions = {}): Promise<void> {
    const described = describeError(error);
    const report = create(CrashReportSchema, {
      id: newId(),
      time: this.#engine.stamp(),
      subject: this.#subject(),
      context: this.#engine.context(),
      exceptionType: described.exceptionType,
      message: this.#engine.scrub(described.message),
      frames: parseStack(described.stack),
      rawStackTrace: described.stack,
      fatal: options.fatal ?? false,
      thread: options.thread ?? "",
      customKeys: this.#properties({}),
      logs: [...this.#crumbs.lines],
    });
    await this.#engine.ingest(
      create(ItemSchema, { kind: { case: "crashReport", value: report } }),
      this.#consent(),
    );
  }

  attempt<T>(action: () => Promise<T>): Promise<T>;
  attempt<T>(action: () => T): T;
  attempt(action: () => unknown): unknown {
    const record = (error: unknown): void => {
      this.recordError(error, { fatal: false }).catch(() => undefined);
    };
    const outcome = ((): unknown => {
      try {
        return action();
      } catch (error: unknown) {
        record(error);
        throw error;
      }
    })();
    return isPromise(outcome)
      ? outcome.catch((error: unknown) => {
          record(error);
          throw error;
        })
      : outcome;
  }

  log(message: string, level: Level = "info"): void {
    const line = create(LogLineSchema, {
      time: this.#engine.stamp(),
      level: levels[level],
      message: this.#engine.scrub(message),
    });
    const lines = [...this.#crumbs.lines, line];
    this.#crumbs.lines =
      lines.length > this.#engine.logLimit
        ? lines.slice(lines.length - this.#engine.logLimit)
        : lines;
  }

  span(name: string): Span {
    const started = this.#engine.now();
    return {
      end: (properties = {}) =>
        this.track(name, { ...properties, duration_ms: this.#engine.now() - started }),
    };
  }

  #consent(): Consent | undefined {
    return this.#identity.kind === "device" ? undefined : this.#identity.consent;
  }

  #subject(): Subject {
    if (this.#identity.kind === "device") {
      return this.#engine.deviceSubject();
    }
    const { ids } = this.#identity;
    return create(SubjectSchema, {
      deviceId: ids.deviceId,
      sessionId: ids.sessionId,
      ...(ids.userId === undefined ? {} : { userId: ids.userId }),
    });
  }

  #properties(properties: Properties) {
    return scrubProperties(this.#engine.scrub, propertiesOf({ ...this.#scope, ...properties }));
  }

  async #profile(changes: readonly ProfileOperation[]): Promise<void> {
    const user = this.userId;
    if (user === undefined) {
      this.#engine.misuse("no-user", "people operations need an identified user");
      return;
    }
    const subject = this.#subject();
    const update = create(ProfileUpdateSchema, {
      id: newId(),
      time: this.#engine.stamp(),
      deviceId: subject.deviceId,
      userId: user,
      operations: [...changes],
    });
    await this.#engine.ingest(
      create(ItemSchema, { kind: { case: "profileUpdate", value: update } }),
      this.#consent(),
    );
  }
}
