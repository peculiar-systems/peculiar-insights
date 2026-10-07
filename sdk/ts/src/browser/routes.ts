import type { Insights } from "../core/insights.ts";

type HistoryMethod = "pushState" | "replaceState";

type Navigate = (this: History, ...args: Parameters<History["pushState"]>) => void;

const isNavigate = (value: unknown): value is Navigate => typeof value === "function";

const patched = (name: HistoryMethod, after: () => void): (() => void) => {
  const original: unknown = Object.getOwnPropertyDescriptor(History.prototype, name)?.value;
  if (!isNavigate(original)) {
    return () => undefined;
  }
  const replacement: Navigate = function replacement(...args) {
    original.apply(this, args);
    after();
  };
  globalThis.history[name] = replacement;
  return () => {
    globalThis.history[name] = original;
  };
};

export const trackRoutes = (insights: Insights): (() => void) => {
  const record = (): void => {
    insights.tracker
      .track("screen_viewed", { path: globalThis.location.pathname })
      .catch(() => undefined);
  };
  const restorePush = patched("pushState", record);
  const restoreReplace = patched("replaceState", record);
  globalThis.addEventListener("popstate", record);
  record();
  return () => {
    restorePush();
    restoreReplace();
    globalThis.removeEventListener("popstate", record);
  };
};

export const trackVisibility = (insights: Insights): (() => void) => {
  const record = (): void => {
    const hidden = globalThis.document.visibilityState === "hidden";
    insights.tracker.track(hidden ? "app_backgrounded" : "app_foregrounded").catch(() => undefined);
    if (hidden) {
      insights.flush().catch(() => undefined);
    }
  };
  globalThis.document.addEventListener("visibilitychange", record);
  return () => {
    globalThis.document.removeEventListener("visibilitychange", record);
  };
};
