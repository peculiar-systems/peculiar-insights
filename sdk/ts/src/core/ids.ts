declare const brand: unique symbol;

type Branded<Name extends string> = string & { readonly [brand]: Name };

export type UserId = Branded<"UserId">;

export type DeviceId = Branded<"DeviceId">;

export type SessionId = Branded<"SessionId">;

const isUserId = (value: string): value is UserId => value.length > 0;

const isDeviceId = (value: string): value is DeviceId => value.length > 0;

const isSessionId = (value: string): value is SessionId => value.length > 0;

const empty = (kind: string): Error => new Error(`peculiar-insights: a ${kind} cannot be empty`);

export const UserId = (value: string): UserId => {
  if (isUserId(value)) {
    return value;
  }
  throw empty("user id");
};

export const DeviceId = (value: string): DeviceId => {
  if (isDeviceId(value)) {
    return value;
  }
  throw empty("device id");
};

export const SessionId = (value: string): SessionId => {
  if (isSessionId(value)) {
    return value;
  }
  throw empty("session id");
};

export const newId = (): string => globalThis.crypto.randomUUID();
