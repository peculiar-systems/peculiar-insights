import { ConsentPolicy, createInsights, trackRoutes, UserId } from "../src/browser/index.ts";

const insights = await createInsights({
  url: "https://insights.example.org",
  key: "replace-with-the-ingest-key",
  app: { version: "1.0.0", build: "20260101120000" },
  consent: ConsentPolicy.ask(),
});

insights.diagnostics((diagnostic) => {
  console.warn("insights", diagnostic);
});

trackRoutes(insights);

export const acceptAll = async (): Promise<void> => {
  await insights.consent.grant("analytics", "2026-01");
  await insights.consent.grant("diagnostics", "2026-01");
};

export const acceptCrashesOnly = (): Promise<void> =>
  insights.consent.grant("diagnostics", "2026-01");

export const onLogin = async (id: string, plan: string): Promise<void> => {
  const tracker = await insights.tracker.identify(UserId(id));
  await tracker.people.set({ plan });
};

const checkout = insights.tracker.with({ screen: "checkout" });

export const onCheckoutOpened = (total: number, items: number): Promise<void> =>
  checkout.track("checkout_opened", { total, items });

export const pay = (charge: () => Promise<void>): Promise<void> => {
  const span = checkout.span("payment_completed");
  return checkout.attempt(charge).then(() => span.end());
};

export const onLogout = (): Promise<void> => insights.tracker.reset();

export const forgetMe = (): Promise<void> => insights.erase();
