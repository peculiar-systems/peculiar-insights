import assert from "node:assert/strict";
import { test } from "node:test";
import { create } from "@bufbuild/protobuf";
import {
  CrashReportSchema,
  EventSchema,
  ItemSchema,
  type Item,
} from "../gen/peculiar/insights/v1/ingest_pb.js";
import { buffered, discarded, drained, emptyBuffer } from "./buffer.ts";

const event = (id: string): Item =>
  create(ItemSchema, { kind: { case: "event", value: create(EventSchema, { id }) } });

const crash = (id: string): Item =>
  create(ItemSchema, { kind: { case: "crashReport", value: create(CrashReportSchema, { id }) } });

await test("the buffer drops the oldest item past its limit", () => {
  const filled = [event("a"), event("b"), event("c")].reduce(buffered, emptyBuffer(2));
  assert.deepEqual(
    filled.items.map((item) => item.kind.value?.id),
    ["b", "c"],
  );
});

await test("draining a purpose takes only its items", () => {
  const buffer = [event("a"), crash("x"), event("b")].reduce(buffered, emptyBuffer(10));
  const { taken, rest } = drained(buffer, "analytics");
  assert.deepEqual(
    taken.map((item) => item.kind.value?.id),
    ["a", "b"],
  );
  assert.deepEqual(
    rest.items.map((item) => item.kind.value?.id),
    ["x"],
  );
});

await test("discarding a purpose keeps the other", () => {
  const buffer = [event("a"), crash("x")].reduce(buffered, emptyBuffer(10));
  assert.deepEqual(
    discarded(buffer, "diagnostics").items.map((item) => item.kind.value?.id),
    ["a"],
  );
});
