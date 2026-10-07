import { create } from "@bufbuild/protobuf";
import { timestampDate } from "@bufbuild/protobuf/wkt";
import { createRouterTransport, type Transport } from "@connectrpc/connect";
import type { Value } from "../gen/peculiar/insights/v1/common_pb.js";
import {
  Ingest,
  ItemOutcomeSchema,
  Outcome,
  PublishResponseSchema,
  RecordConsentResponseSchema,
  RequestErasureResponseSchema,
  type CrashReport,
  type PublishRequest,
  type RecordConsentRequest,
  type RequestErasureRequest,
} from "../gen/peculiar/insights/v1/ingest_pb.js";

export type Plain =
  | string
  | number
  | bigint
  | boolean
  | Date
  | readonly Plain[]
  | { readonly [key: string]: Plain }
  | undefined;

export const plainOf = (value: Value): Plain => {
  const { kind } = value;
  switch (kind.case) {
    case "stringValue":
    case "doubleValue":
    case "boolValue": {
      return kind.value;
    }
    case "intValue": {
      return Number.isSafeInteger(Number(kind.value)) ? Number(kind.value) : kind.value;
    }
    case "timeValue": {
      return timestampDate(kind.value);
    }
    case "listValue": {
      return kind.value.values.map(plainOf);
    }
    case "mapValue": {
      return Object.fromEntries(
        Object.entries(kind.value.entries).map(([key, inner]) => [key, plainOf(inner)]),
      );
    }
    case undefined: {
      return undefined;
    }
  }
};

export type RecordedEvent = {
  readonly name: string;
  readonly properties: { readonly [key: string]: Plain };
  readonly userId: string | undefined;
};

export type Recording = {
  readonly transport: Transport;
  readonly published: readonly PublishRequest[];
  readonly consents: readonly RecordConsentRequest[];
  readonly erasures: readonly RequestErasureRequest[];
  readonly events: () => readonly RecordedEvent[];
  readonly errors: () => readonly CrashReport[];
};

const eventsOf = (published: readonly PublishRequest[]): readonly RecordedEvent[] =>
  published.flatMap((request) =>
    request.items.flatMap((item) =>
      item.kind.case === "event"
        ? [
            {
              name: item.kind.value.name,
              properties: Object.fromEntries(
                Object.entries(item.kind.value.properties).map(([key, value]) => [
                  key,
                  plainOf(value),
                ]),
              ),
              userId: item.kind.value.subject?.userId,
            },
          ]
        : [],
    ),
  );

const errorsOf = (published: readonly PublishRequest[]): readonly CrashReport[] =>
  published.flatMap((request) =>
    request.items.flatMap((item) => (item.kind.case === "crashReport" ? [item.kind.value] : [])),
  );

export const recordingTransport = (): Recording => {
  const published: PublishRequest[] = [];
  const consents: RecordConsentRequest[] = [];
  const erasures: RequestErasureRequest[] = [];
  const transport = createRouterTransport(({ service }) => {
    service(Ingest, {
      publish: (request) => {
        published.push(request);
        return create(PublishResponseSchema, {
          outcomes: request.items.map((item) =>
            create(ItemOutcomeSchema, { id: item.kind.value?.id ?? "", outcome: Outcome.ACCEPTED }),
          ),
        });
      },
      recordConsent: (request) => {
        consents.push(request);
        return create(RecordConsentResponseSchema, { outcome: Outcome.ACCEPTED });
      },
      requestErasure: (request) => {
        erasures.push(request);
        return create(RequestErasureResponseSchema, { outcome: Outcome.ACCEPTED });
      },
    });
  });
  return {
    transport,
    published,
    consents,
    erasures,
    events: () => eventsOf(published),
    errors: () => errorsOf(published),
  };
};
