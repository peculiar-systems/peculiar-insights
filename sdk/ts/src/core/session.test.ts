import assert from "node:assert/strict";
import { test } from "node:test";
import { advanced, sessionTimeoutMs } from "./session.ts";

const fresh = () => "fresh";

await test("no session starts one", () => {
  assert.deepEqual(advanced(undefined, 1000, fresh), { id: "fresh", lastActivity: 1000 });
});

await test("activity inside the timeout keeps the session", () => {
  const session = { id: "kept", lastActivity: 1000 };
  assert.deepEqual(advanced(session, 1000 + sessionTimeoutMs, fresh), {
    id: "kept",
    lastActivity: 1000 + sessionTimeoutMs,
  });
});

await test("activity past the timeout starts a new session", () => {
  const session = { id: "old", lastActivity: 1000 };
  assert.equal(advanced(session, 1001 + sessionTimeoutMs, fresh).id, "fresh");
});

await test("a clock that moved backwards starts a new session", () => {
  const session = { id: "old", lastActivity: 5000 };
  assert.equal(advanced(session, 4000, fresh).id, "fresh");
});
