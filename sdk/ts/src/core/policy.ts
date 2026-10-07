import type { Consent, Purpose } from "./consent.ts";

export type ConsentStore = {
  readonly load: () => Promise<Consent | undefined>;
  readonly save: (consent: Consent) => Promise<void>;
};

export type Basis = Readonly<Partial<Record<Purpose, string>>>;

export type ConsentPolicy =
  | { readonly kind: "ask"; readonly store?: ConsentStore }
  | { readonly kind: "assumed"; readonly basis: Basis };

export const ConsentPolicy = {
  ask: (options: { readonly store?: ConsentStore } = {}): ConsentPolicy => ({
    kind: "ask",
    ...(options.store === undefined ? {} : { store: options.store }),
  }),
  assumed: (basis: Basis): ConsentPolicy => ({ kind: "assumed", basis }),
};

export const grantedConsent = (versions: Basis): Consent => ({
  ...(versions.analytics === undefined
    ? {}
    : { analytics: { state: "granted", policyVersion: versions.analytics } }),
  ...(versions.diagnostics === undefined
    ? {}
    : { diagnostics: { state: "granted", policyVersion: versions.diagnostics } }),
});
