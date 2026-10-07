import { Platform } from "../gen/peculiar/insights/v1/common_pb.js";
import type { Environment } from "../core/context.ts";
import type { Session, SessionStore } from "../core/session.ts";
import { fieldOf } from "../core/storage.ts";

const osOf = (agent: string): { readonly name: string; readonly version: string } => {
  const patterns: readonly (readonly [string, RegExp])[] = [
    ["iOS", /(?:iPhone|iPad|iPod).*? OS (\d+[._]\d+)/u],
    ["Android", /Android (\d+(?:\.\d+)?)/u],
    ["Windows", /Windows NT (\d+\.\d+)/u],
    ["macOS", /Mac OS X (\d+[._]\d+)/u],
    ["ChromeOS", /CrOS [^ ]+ (\d+\.\d+)/u],
    ["Linux", /Linux/u],
  ];
  for (const [name, pattern] of patterns) {
    const match = pattern.exec(agent);
    if (match !== null) {
      return { name, version: (match[1] ?? "").replaceAll("_", ".") };
    }
  }
  return { name: "", version: "" };
};

export const browserEnvironment = (): Environment => {
  const os = osOf(globalThis.navigator.userAgent);
  return {
    platform: Platform.WEB,
    osName: os.name,
    osVersion: os.version,
    deviceModel: "",
    locale: globalThis.navigator.language,
    timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
    screenWidth: globalThis.screen.width,
    screenHeight: globalThis.screen.height,
  };
};

export const globalPrivacyControl = (): boolean =>
  fieldOf(globalThis.navigator, "globalPrivacyControl") === true;

const sessionKey = "peculiar-insights.session";

const parseSession = (raw: string | null): Session | undefined => {
  if (raw === null) {
    return undefined;
  }
  const parsed: unknown = JSON.parse(raw);
  if (typeof parsed !== "object" || parsed === null) {
    return undefined;
  }
  const id = fieldOf(parsed, "id");
  const lastActivity = fieldOf(parsed, "lastActivity");
  return typeof id === "string" && typeof lastActivity === "number"
    ? { id, lastActivity }
    : undefined;
};

export const localStorageSessionStore = (): SessionStore => {
  const fallback: { current: Session | undefined } = { current: undefined };
  return {
    load: () => {
      try {
        return parseSession(globalThis.localStorage.getItem(sessionKey)) ?? fallback.current;
      } catch {
        return fallback.current;
      }
    },
    save: (session) => {
      fallback.current = session;
      try {
        globalThis.localStorage.setItem(sessionKey, JSON.stringify(session));
      } catch {
        fallback.current = session;
      }
    },
  };
};
