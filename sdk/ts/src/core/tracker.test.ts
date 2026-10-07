import assert from "node:assert/strict";
import { test } from "node:test";
import { ConsentState } from "../gen/peculiar/insights/v1/common_pb.js";
import { harness } from "./harness.ts";
import { DeviceId, SessionId, UserId } from "./ids.ts";
import { Insights } from "./insights.ts";
import { grantedConsent } from "./policy.ts";
import { memoryStorage } from "./storage.ts";
import { recordingTransport } from "./testing.ts";

await test("child trackers fold scoped properties, child overriding parent", async () => {
  const recorder = recordingTransport();
  const { options } = harness();
  const insights = await Insights.create({ ...options, transport: recorder.transport });
  await insights.consent.grant("analytics", "v1");
  const screen = insights.tracker.with({ screen: "checkout", step: 1 });
  await screen.with({ step: 2 }).track("advanced", { total: 9.5 });
  await screen.track("stayed");
  await insights.flush();
  assert.deepEqual(
    recorder.events().map((event) => [event.name, event.properties]),
    [
      ["advanced", { screen: "checkout", step: 2, total: 9.5 }],
      ["stayed", { screen: "checkout", step: 1 }],
    ],
  );
  insights.dispose();
});

await test("a span tracks its event with the elapsed duration", async () => {
  const recorder = recordingTransport();
  const clock = { now: 1000 };
  const { options } = harness();
  const insights = await Insights.create({
    ...options,
    transport: recorder.transport,
    now: () => clock.now,
  });
  await insights.consent.grant("analytics", "v1");
  const span = insights.tracker.span("checkout_completed");
  clock.now = 4500;
  await span.end({ items: 2 });
  await insights.flush();
  assert.deepEqual(recorder.events()[0]?.properties, { items: 2, duration_ms: 3500 });
  insights.dispose();
});

await test("attempt records a non-fatal error and rethrows, sync and async", async () => {
  const recorder = recordingTransport();
  const { options } = harness();
  const insights = await Insights.create({ ...options, transport: recorder.transport });
  await insights.consent.grant("diagnostics", "v1");
  const tracker = insights.tracker.with({ step: "payment" });
  assert.throws(
    () =>
      tracker.attempt(() => {
        throw new Error("declined");
      }),
    /declined/u,
  );
  await assert.rejects(
    tracker.attempt(() => Promise.reject(new Error("timeout"))),
    /timeout/u,
  );
  assert.equal(
    tracker.attempt(() => 42),
    42,
  );
  await insights.flush();
  assert.deepEqual(
    recorder
      .errors()
      .map((report) => [report.message, report.fatal, report.customKeys["step"]?.kind.value]),
    [
      ["declined", false, "payment"],
      ["timeout", false, "payment"],
    ],
  );
  insights.dispose();
});

await test("subject trackers carry their own identity and consent per batch", async () => {
  const recorder = recordingTransport();
  const { options } = harness();
  const insights = await Insights.create({ ...options, transport: recorder.transport });
  const alice = insights.subject(
    { deviceId: DeviceId("d-1"), sessionId: SessionId("s-1"), userId: UserId("alice") },
    grantedConsent({ analytics: "2026-01" }),
  );
  const declined = insights.subject({ deviceId: DeviceId("d-2"), sessionId: SessionId("s-2") }, {});
  await alice.track("order_placed", { total: 10 });
  await declined.track("order_placed", { total: 20 });
  const bob = await insights
    .subject(
      { deviceId: DeviceId("d-3"), sessionId: SessionId("s-3") },
      grantedConsent({ analytics: "2026-01" }),
    )
    .identify(UserId("bob"));
  await bob.track("signed_in");
  await insights.flush();
  assert.deepEqual(
    recorder.events().map((event) => [event.name, event.userId]),
    [
      ["order_placed", "alice"],
      ["signed_in", "bob"],
    ],
  );
  assert.deepEqual(
    recorder.published.map((request) => [
      request.items.length,
      request.consent?.purposes[0]?.state,
      request.consent?.purposes[0]?.policyVersion,
    ]),
    [[3, ConsentState.GRANTED, "2026-01"]],
  );
  assert.equal(insights.deviceId, undefined);
  insights.dispose();
});

await test("device and subject batches are never mixed", async () => {
  const recorder = recordingTransport();
  const { options } = harness(memoryStorage());
  const insights = await Insights.create({ ...options, transport: recorder.transport });
  await insights.consent.grant("analytics", "device-v1");
  await insights.tracker.track("device_event");
  await insights
    .subject(
      { deviceId: DeviceId("d-9"), sessionId: SessionId("s-9") },
      grantedConsent({ analytics: "api-v1" }),
    )
    .track("api_event");
  await insights.tracker.track("device_event_again");
  await insights.flush();
  assert.deepEqual(
    recorder.published.map((request) => [
      request.items.length,
      request.consent?.purposes[0]?.policyVersion,
    ]),
    [
      [1, "device-v1"],
      [1, "api-v1"],
      [1, "device-v1"],
    ],
  );
  insights.dispose();
});

await test("the recording transport exposes plain events for product tests", async () => {
  const recorder = recordingTransport();
  const { options } = harness();
  const insights = await Insights.create({ ...options, transport: recorder.transport });
  await insights.consent.grant("analytics", "v1");
  const when = new Date(1_700_000_000_000);
  await insights.tracker.track("shipped", { when, tags: ["a", "b"], nested: { deep: true } });
  await insights.flush();
  assert.deepEqual(recorder.events(), [
    {
      name: "shipped",
      properties: { when, tags: ["a", "b"], nested: { deep: true } },
      userId: undefined,
    },
  ]);
  insights.dispose();
});
