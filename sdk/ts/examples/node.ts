import {
  ConsentPolicy,
  createInsights,
  DeviceId,
  grantedConsent,
  SessionId,
  UserId,
  type Consent,
} from "../src/node/index.ts";

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

type Request = {
  readonly device: string;
  readonly session: string;
  readonly user?: string;
  readonly consentVersion?: string;
};

const consentOf = (request: Request): Consent =>
  request.consentVersion === undefined ? {} : grantedConsent({ analytics: request.consentVersion });

export const onOrderPlaced = async (request: Request, total: number): Promise<void> => {
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

export const runJob = (name: string, job: () => Promise<void>): Promise<void> => {
  const span = insights.tracker.with({ job: name }).span("job_finished");
  return insights.tracker.attempt(job).then(() => span.end());
};

process.on("SIGTERM", () => {
  insights.flush().finally(() => {
    process.exit(0);
  });
});
