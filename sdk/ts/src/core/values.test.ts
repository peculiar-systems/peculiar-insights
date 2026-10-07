import assert from "node:assert/strict";
import { test } from "node:test";
import { valueOf } from "./values.ts";
import { persistedOf } from "./storage.ts";

await test("safe integers travel as int64", () => {
  assert.deepEqual(valueOf(42).kind, { case: "intValue", value: 42n });
  assert.equal(valueOf(1.5).kind.case, "doubleValue");
  assert.equal(valueOf(2 ** 60).kind.case, "doubleValue");
});

await test("dates travel as timestamps", () => {
  const { kind } = valueOf(new Date(1_700_000_000_000));
  const seconds = kind.case === "timeValue" ? kind.value.seconds : undefined;
  assert.equal(seconds, 1_700_000_000n);
});

await test("nested records and lists are preserved", () => {
  const { kind } = valueOf({ tags: ["a", "b"], on: true });
  const entries = kind.case === "mapValue" ? kind.value.entries : {};
  assert.equal(entries["on"]?.kind.value, true);
  const tags = entries["tags"]?.kind;
  assert.equal(tags?.case === "listValue" ? tags.value.values.length : 0, 2);
});

await test("persisted state is parsed defensively", () => {
  assert.deepEqual(persistedOf(null), { consent: {}, items: [], consents: [] });
  assert.deepEqual(persistedOf({ deviceId: 1, items: "no" }), {
    consent: {},
    items: [],
    consents: [],
  });
  assert.deepEqual(
    persistedOf({
      deviceId: "d",
      userId: "u",
      consent: { analytics: { state: "granted", policyVersion: "v1" } },
      items: [
        { item: 1 },
        { item: 2, consent: { analytics: { state: "granted", policyVersion: "v1" } } },
        "junk",
      ],
      consents: [],
    }),
    {
      deviceId: "d",
      userId: "u",
      consent: { analytics: { state: "granted", policyVersion: "v1" } },
      items: [
        { item: 1 },
        { item: 2, consent: { analytics: { state: "granted", policyVersion: "v1" } } },
      ],
      consents: [],
    },
  );
});
