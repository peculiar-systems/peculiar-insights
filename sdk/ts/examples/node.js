import {
  ConsentPolicy,
  createInsights,
  DeviceId,
  grantedConsent,
  SessionId,
  UserId,
} from "../src/node/index.js";
const insights = await createInsights({
  url: "https://insights.example.org",
  key: process.env["PECULIAR_INSIGHTS_KEY"] ?? "",
  app: { version: "1.0.0", build: "20260101120000" },
  stateDirectory: "/var/lib/shop-api/insights",
  consent: ConsentPolicy.assumed({
    analytics: "service-telemetry",
    diagnostics: "service-telemetry",
  }),
});
insights.diagnostics((diagnostic) => {
  console.warn("insights", diagnostic);
});
await insights.tracker.track("service_started", { runtime: process.version });
const consentOf = (request) =>
  request.consentVersion === undefined ? {} : grantedConsent({ analytics: request.consentVersion });
export const onOrderPlaced = async (request, total) => {
  const tracker = insights.subject(
    {
      deviceId: DeviceId(request.device),
      sessionId: SessionId(request.session),
      ...(request.user === undefined ? {} : { userId: UserId(request.user) }),
    },
    consentOf(request),
  );
  await tracker.with({ channel: "api" }).track("order_placed", { total });
};
export const runJob = (name, job) => {
  const span = insights.tracker.with({ job: name }).span("job_finished");
  return insights.tracker.attempt(job).then(() => span.end());
};
process.on("SIGTERM", () => {
  insights.flush().finally(() => {
    process.exit(0);
  });
});
