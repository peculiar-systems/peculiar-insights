import type { JsonValue } from "@bufbuild/protobuf";
import type { Consent, Decision } from "./consent.ts";
import type { Queued } from "./queue.ts";

export type Persisted = {
  readonly deviceId?: string;
  readonly userId?: string;
  readonly consent: Consent;
  readonly items: readonly Queued[];
  readonly consents: readonly JsonValue[];
};

export const emptyPersisted: Persisted = { consent: {}, items: [], consents: [] };

export const withIdentity = (
  persisted: Persisted,
  deviceId: string | undefined,
  userId: string | undefined,
): Persisted => ({
  consent: persisted.consent,
  items: persisted.items,
  consents: persisted.consents,
  ...(deviceId === undefined ? {} : { deviceId }),
  ...(userId === undefined ? {} : { userId }),
});

export type Storage = {
  readonly load: () => Promise<Persisted | undefined>;
  readonly save: (state: Persisted) => Promise<void>;
  readonly clear: () => Promise<void>;
};

export const memoryStorage = (): Storage => {
  const cell: { current: Persisted | undefined } = { current: undefined };
  return {
    load: () => Promise.resolve(cell.current),
    save: (state) => {
      cell.current = state;
      return Promise.resolve();
    },
    clear: () => {
      cell.current = undefined;
      return Promise.resolve();
    },
  };
};

const isJsonArray = (input: unknown): input is readonly JsonValue[] => Array.isArray(input);

const isJsonValue = (input: unknown): input is JsonValue =>
  input !== undefined && typeof input !== "function" && typeof input !== "symbol";

export const fieldOf = (input: object, key: string): unknown =>
  Object.entries(input).find(([name]) => name === key)?.[1];

const decisionOf = (input: unknown): Decision | undefined => {
  if (typeof input !== "object" || input === null) {
    return undefined;
  }
  const state = fieldOf(input, "state");
  const policyVersion = fieldOf(input, "policyVersion");
  return (state === "granted" || state === "withdrawn") && typeof policyVersion === "string"
    ? { state, policyVersion }
    : undefined;
};

const consentOf = (input: unknown): Consent => {
  if (typeof input !== "object" || input === null) {
    return {};
  }
  const analytics = decisionOf(fieldOf(input, "analytics"));
  const diagnostics = decisionOf(fieldOf(input, "diagnostics"));
  return {
    ...(analytics === undefined ? {} : { analytics }),
    ...(diagnostics === undefined ? {} : { diagnostics }),
  };
};

const queuedOf = (input: unknown): Queued | undefined => {
  if (typeof input !== "object" || input === null) {
    return undefined;
  }
  const item = fieldOf(input, "item");
  const consent = fieldOf(input, "consent");
  if (!isJsonValue(item)) {
    return undefined;
  }
  return consent === undefined ? { item } : { item, consent: consentOf(consent) };
};

const queueOf = (input: unknown): readonly Queued[] =>
  Array.isArray(input) ? input.flatMap((entry: unknown) => queuedOf(entry) ?? []) : [];

export const persistedOf = (input: unknown): Persisted => {
  if (typeof input !== "object" || input === null) {
    return emptyPersisted;
  }
  const deviceId = fieldOf(input, "deviceId");
  const userId = fieldOf(input, "userId");
  const consents = fieldOf(input, "consents");
  return {
    ...(typeof deviceId === "string" ? { deviceId } : {}),
    ...(typeof userId === "string" ? { userId } : {}),
    consent: consentOf(fieldOf(input, "consent")),
    items: queueOf(fieldOf(input, "items")),
    consents: isJsonArray(consents) ? consents : [],
  };
};
