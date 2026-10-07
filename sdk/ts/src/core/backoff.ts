import { Code } from "@connectrpc/connect";

export const rateLimited = (code: Code): boolean => code === Code.ResourceExhausted;

export const retryable = (code: Code): boolean =>
  code === Code.Unavailable || code === Code.Unknown || rateLimited(code);

export const baseDelayMs = 1000;

export const maxDelayMs = 60_000;

export const maxPushbackMs = 300_000;

export const pushbackHeader = "x-peculiar-retry-after-ms";

export const delayMs = (attempt: number, random: () => number = Math.random): number => {
  const exponential = Math.min(maxDelayMs, baseDelayMs * 2 ** Math.max(0, attempt));
  return Math.round(exponential * (0.5 + random() / 2));
};

export const pushbackMs = (metadata: Headers): number | undefined => {
  const raw = metadata.get(pushbackHeader);
  return raw !== null && /^\d+$/u.test(raw) ? Math.min(maxPushbackMs, Number(raw)) : undefined;
};

export const pauseMs = (
  metadata: Headers,
  attempt: number,
  random: () => number = Math.random,
): number => pushbackMs(metadata) ?? delayMs(attempt, random);
