import assert from "node:assert/strict";
import { test } from "node:test";
import { Code } from "@connectrpc/connect";
import { ConsentState } from "../gen/peculiar/insights/v1/common_pb.js";
import { Purpose } from "../gen/peculiar/insights/v1/options_pb.js";
import type { Diagnostic } from "./diagnostics.ts";
import { harness, type Received } from "./harness.ts";
import { UserId } from "./ids.ts";
import { Insights } from "./insights.ts";
import { ConsentPolicy } from "./policy.ts";
import { memoryStorage } from "./storage.ts";

const kinds = (received: Received): readonly string[] =>
  received.published.flatMap((request) => request.items.map((item) => item.kind.case ?? ""));

await test("nothing leaves before consent and the buffer flushes on grant", async () => {
  const { received, options, storage } = harness();
  const insights = await Insights.create(options);
  await insights.tracker.track("opened", { screen: "home" });
  await insights.flush();
  assert.equal(received.published.length, 0);
  assert.equal((await storage.load())?.deviceId, undefined);
  await insights.consent.grant("analytics", "v1");
  await insights.flush();
  const record = received.consents[0]?.purpose;
  assert.deepEqual(
    [received.consents.length, record?.state, record?.purpose],
    [1, ConsentState.GRANTED, Purpose.ANALYTICS],
  );
  const request = received.published[0];
  assert.deepEqual(
    [
      received.published.length,
      request?.items.length,
      request?.items[0]?.kind.case,
      request?.consent?.purposes[0]?.state,
      request?.sentAt !== undefined,
    ],
    [1, 1, "event", ConsentState.GRANTED, true],
  );
  const headers = received.headers[0];
  assert.deepEqual(
    [headers?.get("authorization"), headers?.get("x-peculiar-protocol")],
    ["Bearer secret-key", "1"],
  );
  assert.equal((await storage.load())?.deviceId, insights.deviceId);
  insights.dispose();
});

await test("an assumed policy grants at start and records the basis", async () => {
  const { received, options } = harness(
    memoryStorage(),
    ConsentPolicy.assumed({ analytics: "legitimate-interest" }),
  );
  const insights = await Insights.create(options);
  await insights.tracker.track("opened");
  await insights.flush();
  assert.deepEqual(
    [received.consents[0]?.purpose?.policyVersion, kinds(received)],
    ["legitimate-interest", ["event"]],
  );
  assert.equal(insights.consent.status().diagnostics, undefined);
  insights.dispose();
});

await test("an ask policy with a store loads and saves decisions there", async () => {
  const cell: { current: Parameters<Insights["consent"]["grant"]> | undefined } = {
    current: undefined,
  };
  const saved: unknown[] = [];
  const store = {
    load: () =>
      Promise.resolve(
        cell.current === undefined
          ? undefined
          : { analytics: { state: "granted" as const, policyVersion: "stored" } },
      ),
    save: (consent: unknown) => {
      saved.push(consent);
      return Promise.resolve();
    },
  };
  cell.current = ["analytics", "stored"];
  const { received, options } = harness(memoryStorage(), ConsentPolicy.ask({ store }));
  const insights = await Insights.create(options);
  await insights.tracker.track("opened");
  await insights.flush();
  assert.deepEqual(kinds(received), ["event"]);
  await insights.consent.withdraw("analytics");
  assert.equal(saved.length, 1);
  insights.dispose();
});

await test("a crash before a diagnostics decision waits while analytics flows", async () => {
  const { received, options } = harness();
  const insights = await Insights.create(options);
  await insights.consent.grant("analytics", "v1");
  await insights.tracker.recordError(new Error("boom"));
  await insights.tracker.track("opened");
  await insights.flush();
  assert.deepEqual(kinds(received), ["event"]);
  await insights.consent.grant("diagnostics", "v1");
  await insights.flush();
  assert.deepEqual(kinds(received), ["event", "crashReport"]);
  insights.dispose();
});

await test("a denial without a prior grant discards and sends nothing", async () => {
  const { received, options } = harness();
  const insights = await Insights.create(options);
  await insights.tracker.track("opened");
  await insights.consent.withdraw("analytics", "v1");
  await insights.flush();
  assert.deepEqual(
    [received.consents.length, received.published.length, insights.deviceId],
    [0, 0, undefined],
  );
  insights.dispose();
});

await test("withdrawal after a grant sends one record and drops the identity", async () => {
  const { received, options, storage } = harness();
  const insights = await Insights.create(options);
  await insights.consent.grant("analytics", "v1");
  await insights.tracker.identify(UserId("alice"));
  const device = insights.deviceId;
  await insights.consent.withdraw("analytics");
  await insights.flush();
  assert.deepEqual(
    received.consents.map((record) => [record.purpose?.state, record.deviceId]),
    [
      [ConsentState.GRANTED, device],
      [ConsentState.WITHDRAWN, device],
    ],
  );
  assert.deepEqual(
    [insights.deviceId, insights.userId, (await storage.load())?.deviceId],
    [undefined, undefined, undefined],
  );
  insights.dispose();
});

await test("transport failures keep the queue, retry, and surface as diagnostics", async () => {
  const { received, options, storage } = harness();
  const insights = await Insights.create(options);
  const seen: Diagnostic[] = [];
  insights.diagnostics((diagnostic) => {
    seen.push(diagnostic);
  });
  await insights.consent.grant("analytics", "v1");
  await insights.flush();
  received.failures = 2;
  await insights.tracker.track("opened");
  await insights.flush();
  assert.equal((await storage.load())?.items.length, 1);
  await insights.flush();
  await insights.flush();
  assert.equal(received.published.length, 1);
  assert.deepEqual(
    seen.map((diagnostic) => [
      diagnostic.kind,
      diagnostic.kind === "transport-failed" && diagnostic.willRetry,
    ]),
    [
      ["transport-failed", true],
      ["transport-failed", true],
    ],
  );
  insights.dispose();
});

await test("a rejected item reaches the diagnostics stream", async () => {
  const { received, options } = harness();
  const insights = await Insights.create(options);
  const seen: Diagnostic[] = [];
  insights.diagnostics((diagnostic) => {
    seen.push(diagnostic);
  });
  await insights.consent.grant("analytics", "v1");
  received.reject = true;
  await insights.tracker.track("opened");
  await insights.flush();
  assert.deepEqual(
    seen.map((diagnostic) => [
      diagnostic.kind,
      diagnostic.kind === "rejected" && diagnostic.reason,
    ]),
    [["rejected", "bad"]],
  );
  insights.dispose();
});

await test("identify and people operations carry the user id", async () => {
  const { received, options } = harness();
  const insights = await Insights.create(options);
  await insights.consent.grant("analytics", "v1");
  const tracker = await insights.tracker.identify(UserId("alice"));
  await tracker.people.set({ plan: "pro" });
  await tracker.people.setOnce({ signedUp: new Date(0) });
  await tracker.people.unset(["trial"]);
  await tracker.track("opened");
  await insights.flush();
  const items = received.published.flatMap((request) => request.items);
  assert.deepEqual(
    items.map((item) => item.kind.case),
    ["identify", "profileUpdate", "profileUpdate", "profileUpdate", "event"],
  );
  const event = items[4]?.kind;
  assert.equal(event?.case === "event" ? event.value.subject?.userId : undefined, "alice");
  assert.deepEqual(
    items
      .slice(1, 4)
      .map((item) =>
        item.kind.case === "profileUpdate" ? item.kind.value.operations[0]?.kind.case : undefined,
      ),
    ["set", "setOnce", "unset"],
  );
  insights.dispose();
});

await test("people operations without a user are dropped with a diagnostic", async () => {
  const { received, options } = harness();
  const insights = await Insights.create(options);
  const seen: Diagnostic[] = [];
  insights.diagnostics((diagnostic) => {
    seen.push(diagnostic);
  });
  await insights.consent.grant("analytics", "v1");
  await insights.tracker.people.set({ plan: "pro" });
  await insights.flush();
  assert.deepEqual(
    [kinds(received), seen.map((diagnostic) => diagnostic.kind === "dropped" && diagnostic.cause)],
    [[], ["no-user"]],
  );
  insights.dispose();
});

await test("misuse throws in debug mode", async () => {
  const { options } = harness();
  const insights = await Insights.create({ ...options, debug: true });
  await insights.consent.grant("analytics", "v1");
  await assert.rejects(insights.tracker.people.set({ plan: "pro" }), /identified user/u);
  await assert.rejects(insights.tracker.track(""), /needs a name/u);
  insights.dispose();
});

await test("queued items survive a restart", async () => {
  const storage = memoryStorage();
  const first = harness(storage);
  const insights = await Insights.create(first.options);
  await insights.consent.grant("analytics", "v1");
  await insights.flush();
  first.received.failures = 100;
  await insights.tracker.track("opened");
  await insights.flush();
  insights.dispose();
  const second = harness(storage);
  const revived = await Insights.create(second.options);
  assert.equal(revived.deviceId, insights.deviceId);
  await revived.flush();
  assert.equal(second.received.published[0]?.items.length, 1);
  revived.dispose();
});

await test("erasure names the device and the linked user and resets local state", async () => {
  const { received, options, storage } = harness();
  const insights = await Insights.create(options);
  await insights.consent.grant("analytics", "v1");
  await insights.tracker.identify(UserId("alice"));
  const device = insights.deviceId;
  await insights.erase();
  assert.deepEqual(
    [received.erasures[0]?.deviceId, received.erasures[0]?.userId, insights.userId],
    [device, "alice", undefined],
  );
  assert.equal((await storage.load())?.items.length, 0);
  assert.equal(insights.consent.status().analytics?.state, "granted");
  insights.dispose();
});

await test("the scrubber redacts crash messages, logs and scoped keys when enabled", async () => {
  const { received, options } = harness();
  const insights = await Insights.create({ ...options, scrub: [] });
  await insights.consent.grant("diagnostics", "v1");
  const tracker = insights.tracker.with({ email: "someone@example.org" });
  tracker.log("user someone@example.org failed");
  await tracker.recordError(new Error("mail to someone@example.org bounced"), { fatal: true });
  await insights.flush();
  const crash = received.published[0]?.items[0]?.kind;
  const report = crash?.case === "crashReport" ? crash.value : undefined;
  assert.deepEqual(
    [
      report?.message,
      report?.logs[0]?.message,
      report?.customKeys["email"]?.kind.value,
      report?.fatal,
    ],
    ["mail to [redacted] bounced", "user [redacted] failed", "[redacted]", true],
  );
  insights.dispose();
});

await test("identify before an analytics grant persists nothing until the grant", async () => {
  const { received, options, storage } = harness();
  const insights = await Insights.create(options);
  await insights.tracker.identify(UserId("alice"));
  assert.equal(insights.userId, "alice");
  assert.equal((await storage.load())?.userId, undefined);
  await insights.consent.grant("analytics", "v1");
  assert.equal((await storage.load())?.userId, "alice");
  await insights.flush();
  assert.equal(received.published.length, 1);
  insights.dispose();
});

const names = (received: Received): readonly string[] =>
  received.published.flatMap((request) =>
    request.items.map((item) => (item.kind.case === "event" ? item.kind.value.name : "")),
  );

await test("a rate limited batch stays queued and is delivered once when accepted", async () => {
  const { received, options, storage } = harness();
  const insights = await Insights.create(options);
  const seen: Diagnostic[] = [];
  insights.diagnostics((diagnostic) => {
    seen.push(diagnostic);
  });
  await insights.consent.grant("analytics", "v1");
  await insights.flush();
  received.refusals.push({ pushback: "1500" }, { pushback: "1500" });
  await insights.tracker.track("opened");
  await insights.tracker.track("scrolled");
  await insights.tracker.track("closed");
  await insights.flush();
  assert.deepEqual([(await storage.load())?.items.length, received.published.length], [3, 0]);
  await insights.flush();
  assert.deepEqual([(await storage.load())?.items.length, received.published.length], [3, 0]);
  await insights.flush();
  await insights.flush();
  assert.deepEqual(
    [(await storage.load())?.items.length, received.published.length, names(received)],
    [0, 1, ["opened", "scrolled", "closed"]],
  );
  assert.deepEqual(
    seen.map((diagnostic) =>
      diagnostic.kind === "transport-failed"
        ? [diagnostic.kind, diagnostic.code, diagnostic.willRetry]
        : [diagnostic.kind],
    ),
    [
      ["transport-failed", Code.ResourceExhausted, true],
      ["transport-failed", Code.ResourceExhausted, true],
    ],
  );
  insights.dispose();
});

await test("the delay the server asks for replaces the backoff and is capped", async () => {
  const { received, options, waits } = harness();
  const insights = await Insights.create(options);
  await insights.consent.grant("analytics", "v1");
  await insights.flush();
  received.refusals.push({ pushback: "2500" }, { pushback: "0" }, { pushback: "900000" });
  await insights.tracker.track("opened");
  await insights.flush();
  await insights.flush();
  await insights.flush();
  assert.deepEqual([waits, received.published.length], [[2500, 0, 300_000], 0]);
  await insights.flush();
  assert.deepEqual([waits, names(received)], [[2500, 0, 300_000], ["opened"]]);
  insights.dispose();
});

await test("an absent or malformed pushback falls back to the backoff", async () => {
  const { received, options, waits } = harness();
  const insights = await Insights.create(options);
  await insights.consent.grant("analytics", "v1");
  await insights.flush();
  received.refusals.push({ pushback: "soon" }, {}, { pushback: "-1" });
  await insights.tracker.track("opened");
  await insights.flush();
  await insights.flush();
  await insights.flush();
  assert.deepEqual([waits, received.published.length], [[1000, 2000, 4000], 0]);
  await insights.flush();
  assert.deepEqual(names(received), ["opened"]);
  insights.dispose();
});

await test("a rate limited consent record is kept and sent once", async () => {
  const { received, options, storage, waits } = harness();
  const insights = await Insights.create(options);
  received.refusals.push({ pushback: "700" });
  await insights.consent.grant("analytics", "v1");
  await insights.tracker.track("opened");
  await insights.flush();
  await insights.flush();
  const stored = await storage.load();
  assert.deepEqual(
    [waits, received.consents.length, names(received), stored?.consents.length],
    [[700], 1, ["opened"], 0],
  );
  insights.dispose();
});

await test("erasure outlasts rate limiting beyond the attempt limit", async () => {
  const { received, options, waits } = harness();
  const insights = await Insights.create(options);
  const seen: Diagnostic[] = [];
  insights.diagnostics((diagnostic) => {
    seen.push(diagnostic);
  });
  await insights.consent.grant("analytics", "v1");
  await insights.flush();
  received.refusals.push(...Array.from({ length: 8 }, () => ({ pushback: "40" })));
  await insights.erase();
  assert.deepEqual(
    [received.erasures.length, waits, seen.length],
    [1, [40, 40, 40, 40, 40, 40, 40, 40], 8],
  );
  assert.equal(
    seen.every((diagnostic) => diagnostic.kind === "transport-failed" && diagnostic.willRetry),
    true,
  );
  insights.dispose();
});
