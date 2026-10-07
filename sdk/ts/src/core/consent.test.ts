import assert from "node:assert/strict";
import { test } from "node:test";
import { ConsentState } from "../gen/peculiar/insights/v1/common_pb.js";
import { Purpose } from "../gen/peculiar/insights/v1/options_pb.js";
import {
  anyGranted,
  decided,
  granted,
  permits,
  snapshotOf,
  undecided,
  withdrawn,
} from "./consent.ts";

await test("nothing is permitted before a decision", () => {
  assert.equal(permits(undecided, "analytics"), false);
  assert.equal(decided(undecided, "analytics"), false);
  assert.equal(anyGranted(undecided), false);
});

await test("a grant permits only its purpose", () => {
  const consent = granted(undecided, "analytics", "v1");
  assert.equal(permits(consent, "analytics"), true);
  assert.equal(permits(consent, "diagnostics"), false);
  assert.equal(anyGranted(consent), true);
});

await test("a withdrawal is decided and not permitted", () => {
  const consent = withdrawn(granted(undecided, "analytics", "v1"), "analytics", "v2");
  assert.equal(permits(consent, "analytics"), false);
  assert.equal(decided(consent, "analytics"), true);
  assert.equal(consent.analytics?.policyVersion, "v2");
});

await test("the snapshot carries every decided purpose", () => {
  const consent = withdrawn(granted(undecided, "analytics", "v1"), "diagnostics", "v1");
  const snapshot = snapshotOf(consent);
  assert.deepEqual(
    snapshot.purposes.map((entry) => [entry.purpose, entry.state, entry.policyVersion]),
    [
      [Purpose.ANALYTICS, ConsentState.GRANTED, "v1"],
      [Purpose.DIAGNOSTICS, ConsentState.WITHDRAWN, "v1"],
    ],
  );
  assert.equal(snapshotOf(undecided).purposes.length, 0);
});
