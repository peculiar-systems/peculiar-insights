import type { JsonValue } from "@bufbuild/protobuf";
import type { Consent } from "./consent.ts";

export type Queued = {
  readonly item: JsonValue;
  readonly consent?: Consent;
};

export const consentKey = (consent: Consent | undefined): string =>
  consent === undefined ? "device" : JSON.stringify(consent);

export const nextBatch = (
  queue: readonly Queued[],
  size: number,
): { readonly batch: readonly Queued[]; readonly consent: Consent | undefined } => {
  const head = queue[0];
  if (head === undefined) {
    return { batch: [], consent: undefined };
  }
  const key = consentKey(head.consent);
  const batch: Queued[] = [];
  for (const entry of queue) {
    if (batch.length >= size || consentKey(entry.consent) !== key) {
      break;
    }
    batch.push(entry);
  }
  return { batch, consent: head.consent };
};
