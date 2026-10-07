import assert from "node:assert/strict";
import { test } from "node:test";
import { Code } from "@connectrpc/connect";
import {
  delayMs,
  maxDelayMs,
  maxPushbackMs,
  pauseMs,
  pushbackHeader,
  pushbackMs,
  rateLimited,
  retryable,
} from "./backoff.ts";

await test("only transport failures retry", () => {
  assert.equal(retryable(Code.Unavailable), true);
  assert.equal(retryable(Code.Unknown), true);
  assert.equal(retryable(Code.ResourceExhausted), true);
  assert.equal(retryable(Code.Unauthenticated), false);
  assert.equal(retryable(Code.InvalidArgument), false);
  assert.equal(retryable(Code.FailedPrecondition), false);
});

const steady = (): number => 1;

await test("delays grow exponentially and cap", () => {
  assert.equal(delayMs(0, steady), 1000);
  assert.equal(delayMs(1, steady), 2000);
  assert.equal(delayMs(3, steady), 8000);
  assert.equal(delayMs(20, steady), maxDelayMs);
});

await test("jitter stays within half of the delay", () => {
  assert.equal(
    delayMs(0, () => 0),
    500,
  );
  assert.equal(
    delayMs(0, () => 1),
    1000,
  );
});

const asked = (value: string): Headers => new Headers({ [pushbackHeader]: value });

await test("only resource exhaustion counts as rate limiting", () => {
  assert.equal(rateLimited(Code.ResourceExhausted), true);
  assert.equal(rateLimited(Code.Unavailable), false);
  assert.equal(rateLimited(Code.Unknown), false);
});

await test("a pushback is read as whole milliseconds and capped", () => {
  assert.equal(pushbackMs(asked("0")), 0);
  assert.equal(pushbackMs(asked("1500")), 1500);
  assert.equal(pushbackMs(asked(String(maxPushbackMs + 1))), maxPushbackMs);
  assert.equal(pushbackMs(asked("99999999999999999999999999")), maxPushbackMs);
});

await test("an absent or malformed pushback is ignored", () => {
  assert.equal(pushbackMs(new Headers()), undefined);
  assert.deepEqual(
    ["", "soon", "-1", "1.5", "1e3", "0x10", "12ms"].map((value) => pushbackMs(asked(value))),
    [undefined, undefined, undefined, undefined, undefined, undefined, undefined],
  );
});

await test("the pause prefers the pushback over the backoff", () => {
  assert.equal(pauseMs(asked("2500"), 3, steady), 2500);
  assert.equal(pauseMs(asked("soon"), 3, steady), 8000);
  assert.equal(pauseMs(new Headers(), 0, steady), 1000);
});
