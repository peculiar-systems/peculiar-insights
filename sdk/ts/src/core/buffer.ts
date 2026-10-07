import type { Item } from "../gen/peculiar/insights/v1/ingest_pb.js";
import { purposeOfItem, type Purpose } from "./consent.ts";

export type Buffer = {
  readonly items: readonly Item[];
  readonly limit: number;
};

export const emptyBuffer = (limit: number): Buffer => ({ items: [], limit });

export const buffered = (buffer: Buffer, item: Item): Buffer => ({
  ...buffer,
  items:
    buffer.items.length >= buffer.limit
      ? [...buffer.items.slice(buffer.items.length - buffer.limit + 1), item]
      : [...buffer.items, item],
});

export const drained = (
  buffer: Buffer,
  purpose: Purpose,
): { readonly taken: readonly Item[]; readonly rest: Buffer } => ({
  taken: buffer.items.filter((item) => purposeOfItem(item) === purpose),
  rest: { ...buffer, items: buffer.items.filter((item) => purposeOfItem(item) !== purpose) },
});

export const discarded = (buffer: Buffer, purpose: Purpose): Buffer =>
  drained(buffer, purpose).rest;
