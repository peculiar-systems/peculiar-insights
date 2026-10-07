import { create } from "@bufbuild/protobuf";
import { Code, ConnectError, createRouterTransport, type Transport } from "@connectrpc/connect";
import { Platform } from "../gen/peculiar/insights/v1/common_pb.js";
import {
  Ingest,
  ItemOutcomeSchema,
  Outcome,
  PublishResponseSchema,
  RecordConsentResponseSchema,
  RequestErasureResponseSchema,
  type PublishRequest,
  type RecordConsentRequest,
  type RequestErasureRequest,
} from "../gen/peculiar/insights/v1/ingest_pb.js";
import type { Environment } from "./context.ts";
import type { Options } from "./insights.ts";
import { ConsentPolicy } from "./policy.ts";
import { memorySessionStore } from "./session.ts";
import { memoryStorage, type Storage } from "./storage.ts";

export type Received = {
  readonly published: PublishRequest[];
  readonly consents: RecordConsentRequest[];
  readonly erasures: RequestErasureRequest[];
  readonly headers: Headers[];
  readonly refusals: Refusal[];
  failures: number;
  reject: boolean;
};

export type Refusal = { readonly pushback?: string };

const refuse = (received: Received): void => {
  const refusal = received.refusals.shift();
  if (refusal !== undefined) {
    throw new ConnectError(
      "rate limited",
      Code.ResourceExhausted,
      refusal.pushback === undefined ? {} : { "x-peculiar-retry-after-ms": refusal.pushback },
    );
  }
};

export const environment: Environment = {
  platform: Platform.WEB,
  osName: "test",
  osVersion: "1",
  deviceModel: "",
  locale: "en",
  timezone: "UTC",
  screenWidth: 1,
  screenHeight: 1,
};

const routerOf = (received: Received): Transport =>
  createRouterTransport(({ service }) => {
    service(Ingest, {
      publish: (request, context) => {
        received.headers.push(context.requestHeader);
        refuse(received);
        if (received.failures > 0) {
          received.failures -= 1;
          throw new ConnectError("down", Code.Unavailable);
        }
        received.published.push(request);
        return create(PublishResponseSchema, {
          outcomes: request.items.map((item) =>
            create(ItemOutcomeSchema, {
              id: item.kind.value?.id ?? "",
              outcome: received.reject ? Outcome.INVALID : Outcome.ACCEPTED,
              reason: received.reject ? "bad" : "",
            }),
          ),
        });
      },
      recordConsent: (request) => {
        refuse(received);
        received.consents.push(request);
        return create(RecordConsentResponseSchema, { outcome: Outcome.ACCEPTED });
      },
      requestErasure: (request) => {
        refuse(received);
        received.erasures.push(request);
        return create(RequestErasureResponseSchema, { outcome: Outcome.ACCEPTED });
      },
    });
  });

export type Harness = {
  readonly received: Received;
  readonly options: Options;
  readonly storage: Storage;
  readonly waits: readonly number[];
};

export const harness = (
  storage: Storage = memoryStorage(),
  policy = ConsentPolicy.ask(),
): Harness => {
  const received: Received = {
    published: [],
    consents: [],
    erasures: [],
    headers: [],
    refusals: [],
    failures: 0,
    reject: false,
  };
  const waits: number[] = [];
  const options: Options = {
    key: "secret-key",
    app: { version: "1.0.0", build: "7" },
    consent: policy,
    transport: routerOf(received),
    storage,
    environment,
    sessionStore: memorySessionStore(),
    flushIntervalMs: 3_600_000,
    schedule: () => () => undefined,
    wait: (ms) => {
      waits.push(ms);
      return Promise.resolve();
    },
    random: () => 1,
  };
  return { received, options, storage, waits };
};
