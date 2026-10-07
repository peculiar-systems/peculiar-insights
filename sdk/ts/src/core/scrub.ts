import { create } from "@bufbuild/protobuf";
import {
  ValueListSchema,
  ValueMapSchema,
  ValueSchema,
  type Value,
} from "../gen/peculiar/insights/v1/common_pb.js";

export type Scrubber = (text: string) => string;

export const builtinPatterns: readonly RegExp[] = [
  /[\w.+-]+@[\w-]+(?:\.[\w-]+)+/gu,
  /(?<!\w)(?:\d[ -]?){13,19}(?!\w)/gu,
  /(?<![\w.])\+?\d[\d ().-]{7,}\d(?![\w.])/gu,
];

export const replacement = "[redacted]";

const global = (pattern: RegExp): RegExp =>
  pattern.flags.includes("g") ? pattern : new RegExp(pattern.source, `${pattern.flags}g`);

export const scrubber = (patterns: readonly RegExp[]): Scrubber => {
  const compiled = patterns.map(global);
  return (text) => compiled.reduce((acc, pattern) => acc.replace(pattern, replacement), text);
};

export const identityScrubber: Scrubber = (text) => text;

export const scrubValue = (scrub: Scrubber, value: Value): Value => {
  const { kind } = value;
  if (kind.case === "stringValue") {
    return create(ValueSchema, { kind: { case: "stringValue", value: scrub(kind.value) } });
  }
  if (kind.case === "listValue") {
    return create(ValueSchema, {
      kind: {
        case: "listValue",
        value: create(ValueListSchema, {
          values: kind.value.values.map((inner) => scrubValue(scrub, inner)),
        }),
      },
    });
  }
  if (kind.case === "mapValue") {
    const entries = Object.fromEntries(
      Object.entries(kind.value.entries).map(([key, inner]) => [key, scrubValue(scrub, inner)]),
    );
    return create(ValueSchema, {
      kind: { case: "mapValue", value: create(ValueMapSchema, { entries }) },
    });
  }
  return value;
};

export const scrubProperties = (
  scrub: Scrubber,
  properties: Readonly<Record<string, Value>>,
): Record<string, Value> =>
  Object.fromEntries(
    Object.entries(properties).map(([key, value]) => [key, scrubValue(scrub, value)]),
  );
