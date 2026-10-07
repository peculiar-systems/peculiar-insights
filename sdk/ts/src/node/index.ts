import type { Transport } from "@connectrpc/connect";
import { createGrpcTransport } from "@connectrpc/connect-node";
import type { AppInfo } from "../core/context.ts";
import { Insights } from "../core/insights.ts";
import type { ConsentPolicy } from "../core/policy.ts";
import { memorySessionStore } from "../core/session.ts";
import type { Storage } from "../core/storage.ts";
import { nodeEnvironment } from "./environment.ts";
import { fileStorage } from "./storage.ts";

export * from "../core/index.ts";

export type NodeOptions = {
  readonly url: string;
  readonly key: string;
  readonly app: AppInfo;
  readonly consent: ConsentPolicy;
  readonly stateDirectory: string;
  readonly debug?: boolean;
  readonly captureErrors?: boolean;
  readonly exitOnUncaught?: boolean;
  readonly scrub?: readonly RegExp[];
  readonly flushIntervalMs?: number;
  readonly batchSize?: number;
  readonly transport?: Transport;
  readonly storage?: Storage;
};

const lastWordsMs = 5000;

const elapsed = async (milliseconds: number): Promise<void> => {
  await new Promise<void>((resolve) => {
    setTimeout(resolve, milliseconds).unref();
  });
};

export const createInsights = async (options: NodeOptions): Promise<Insights> => {
  const insights = await Insights.create({
    key: options.key,
    app: options.app,
    consent: options.consent,
    transport: options.transport ?? createGrpcTransport({ baseUrl: options.url }),
    storage: options.storage ?? fileStorage(options.stateDirectory),
    environment: nodeEnvironment(),
    sessionStore: memorySessionStore(),
    debug: options.debug ?? process.env["NODE_ENV"] !== "production",
    schedule: (run, ms) => {
      const handle = setTimeout(run, ms);
      handle.unref();
      return () => {
        clearTimeout(handle);
      };
    },
    ...(options.scrub === undefined ? {} : { scrub: options.scrub }),
    ...(options.flushIntervalMs === undefined ? {} : { flushIntervalMs: options.flushIntervalMs }),
    ...(options.batchSize === undefined ? {} : { batchSize: options.batchSize }),
  });
  if (options.captureErrors !== false) {
    process.on("uncaughtException", (error) => {
      insights.tracker
        .recordError(error, { fatal: true })
        .then(() => Promise.race([insights.flush(), elapsed(lastWordsMs)]))
        .catch(() => undefined)
        .finally(() => {
          if (options.exitOnUncaught !== false) {
            process.exit(1);
          }
        });
    });
    process.on("unhandledRejection", (reason) => {
      insights.tracker.recordError(reason, { fatal: false }).catch(() => undefined);
    });
  }
  return insights;
};
