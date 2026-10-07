import type { Transport } from "@connectrpc/connect";
import { createGrpcWebTransport } from "@connectrpc/connect-web";
import { withdrawn, type Consent } from "../core/consent.ts";
import type { AppInfo } from "../core/context.ts";
import { Insights } from "../core/insights.ts";
import type { ConsentPolicy } from "../core/policy.ts";
import type { Storage } from "../core/storage.ts";
import {
  browserEnvironment,
  globalPrivacyControl,
  localStorageSessionStore,
} from "./environment.ts";
import { indexedDbStorage } from "./storage.ts";

export * from "../core/index.ts";
export { trackRoutes, trackVisibility } from "./routes.ts";

export type BrowserOptions = {
  readonly url: string;
  readonly key: string;
  readonly app: AppInfo;
  readonly consent: ConsentPolicy;
  readonly debug?: boolean;
  readonly ignoreGlobalPrivacyControl?: boolean;
  readonly captureErrors?: boolean;
  readonly scrub?: readonly RegExp[];
  readonly flushIntervalMs?: number;
  readonly batchSize?: number;
  readonly transport?: Transport;
  readonly storage?: Storage;
};

const gpcDenial = (): Consent =>
  withdrawn(
    withdrawn({}, "analytics", "global-privacy-control"),
    "diagnostics",
    "global-privacy-control",
  );

export const createInsights = async (options: BrowserOptions): Promise<Insights> => {
  const denied = globalPrivacyControl() && options.ignoreGlobalPrivacyControl !== true;
  const insights = await Insights.create({
    key: options.key,
    app: options.app,
    consent: options.consent,
    transport: options.transport ?? createGrpcWebTransport({ baseUrl: options.url }),
    storage: options.storage ?? indexedDbStorage(),
    environment: browserEnvironment(),
    sessionStore: localStorageSessionStore(),
    ...(denied ? { initialConsent: gpcDenial() } : {}),
    ...(options.debug === undefined ? {} : { debug: options.debug }),
    ...(options.scrub === undefined ? {} : { scrub: options.scrub }),
    ...(options.flushIntervalMs === undefined ? {} : { flushIntervalMs: options.flushIntervalMs }),
    ...(options.batchSize === undefined ? {} : { batchSize: options.batchSize }),
  });
  if (options.captureErrors !== false) {
    globalThis.addEventListener("error", (event) => {
      insights.tracker
        .recordError(event.error ?? event.message, { fatal: true })
        .catch(() => undefined);
    });
    globalThis.addEventListener("unhandledrejection", (event) => {
      insights.tracker.recordError(event.reason, { fatal: false }).catch(() => undefined);
    });
  }
  globalThis.addEventListener("pagehide", () => {
    insights.flush().catch(() => undefined);
  });
  return insights;
};
