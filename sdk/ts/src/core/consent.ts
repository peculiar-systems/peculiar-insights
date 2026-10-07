import { create } from "@bufbuild/protobuf";
import {
  ConsentSnapshotSchema,
  ConsentState,
  PurposeStateSchema,
  type ConsentSnapshot,
} from "../gen/peculiar/insights/v1/common_pb.js";
import type { Item } from "../gen/peculiar/insights/v1/ingest_pb.js";
import { Purpose as PurposeEnum } from "../gen/peculiar/insights/v1/options_pb.js";

export type Purpose = "analytics" | "diagnostics";

export const purposes: readonly Purpose[] = ["analytics", "diagnostics"];

export type Decision = {
  readonly state: "granted" | "withdrawn";
  readonly policyVersion: string;
};

export type Consent = Readonly<Partial<Record<Purpose, Decision>>>;

export const undecided: Consent = {};

export const permits = (consent: Consent, purpose: Purpose): boolean =>
  consent[purpose]?.state === "granted";

export const decided = (consent: Consent, purpose: Purpose): boolean =>
  consent[purpose] !== undefined;

export const anyGranted = (consent: Consent): boolean =>
  purposes.some((purpose) => permits(consent, purpose));

export const granted = (consent: Consent, purpose: Purpose, policyVersion: string): Consent => ({
  ...consent,
  [purpose]: { state: "granted", policyVersion },
});

export const withdrawn = (consent: Consent, purpose: Purpose, policyVersion: string): Consent => ({
  ...consent,
  [purpose]: { state: "withdrawn", policyVersion },
});

const purposeEnums: Readonly<Record<Purpose, PurposeEnum>> = {
  analytics: PurposeEnum.ANALYTICS,
  diagnostics: PurposeEnum.DIAGNOSTICS,
};

export const purposeEnum = (purpose: Purpose): PurposeEnum => purposeEnums[purpose];

const stateEnums: Readonly<Record<Decision["state"], ConsentState>> = {
  granted: ConsentState.GRANTED,
  withdrawn: ConsentState.WITHDRAWN,
};

export const stateEnum = (decision: Decision): ConsentState => stateEnums[decision.state];

export const snapshotOf = (consent: Consent): ConsentSnapshot =>
  create(ConsentSnapshotSchema, {
    purposes: purposes.flatMap((purpose) => {
      const decision = consent[purpose];
      return decision === undefined
        ? []
        : [
            create(PurposeStateSchema, {
              purpose: purposeEnum(purpose),
              state: stateEnum(decision),
              policyVersion: decision.policyVersion,
            }),
          ];
    }),
  });

export const purposeOfItem = (item: Item): Purpose =>
  item.kind.case === "crashReport" ? "diagnostics" : "analytics";
