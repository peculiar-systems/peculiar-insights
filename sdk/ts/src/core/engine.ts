import type { Timestamp } from "@bufbuild/protobuf/wkt";
import type { Context } from "../gen/peculiar/insights/v1/common_pb.js";
import type { Item, LogLine, Subject } from "../gen/peculiar/insights/v1/ingest_pb.js";
import type { Consent } from "./consent.ts";
import type { Diagnostic, DropCause } from "./diagnostics.ts";
import type { UserId } from "./ids.ts";
import type { Scrubber } from "./scrub.ts";

export type Breadcrumbs = {
  lines: readonly LogLine[];
};

export type Engine = {
  readonly ingest: (item: Item, consent: Consent | undefined) => Promise<void>;
  readonly deviceSubject: () => Subject;
  readonly deviceUserId: () => UserId | undefined;
  readonly identifyDevice: (userId: UserId) => Promise<void>;
  readonly resetDevice: () => Promise<void>;
  readonly stamp: () => Timestamp;
  readonly context: () => Context;
  readonly scrub: Scrubber;
  readonly now: () => number;
  readonly logLimit: number;
  readonly report: (diagnostic: Diagnostic) => void;
  readonly misuse: (cause: DropCause, detail: string) => void;
};
