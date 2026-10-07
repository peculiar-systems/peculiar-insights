import { create } from "@bufbuild/protobuf";
import { timestampFromDate } from "@bufbuild/protobuf/wkt";
import {
  ValueListSchema,
  ValueMapSchema,
  ValueSchema,
  type Value,
} from "../gen/peculiar/insights/v1/common_pb.js";

export type PropertyValue =
  | string
  | number
  | boolean
  | bigint
  | Date
  | readonly PropertyValue[]
  | { readonly [key: string]: PropertyValue };

export type Properties = { readonly [key: string]: PropertyValue };

const int64Min = -(2n ** 63n);
const int64Max = 2n ** 63n - 1n;

const isRecord = (input: PropertyValue): input is { readonly [key: string]: PropertyValue } =>
  typeof input === "object" && !Array.isArray(input) && !(input instanceof Date);

export const valueOf = (input: PropertyValue): Value => {
  if (typeof input === "string") {
    return create(ValueSchema, { kind: { case: "stringValue", value: input } });
  }
  if (typeof input === "boolean") {
    return create(ValueSchema, { kind: { case: "boolValue", value: input } });
  }
  if (typeof input === "bigint") {
    const clamped = input < int64Min ? int64Min : input > int64Max ? int64Max : input;
    return create(ValueSchema, { kind: { case: "intValue", value: clamped } });
  }
  if (typeof input === "number") {
    return Number.isSafeInteger(input)
      ? create(ValueSchema, { kind: { case: "intValue", value: BigInt(input) } })
      : create(ValueSchema, { kind: { case: "doubleValue", value: input } });
  }
  if (input instanceof Date) {
    return create(ValueSchema, { kind: { case: "timeValue", value: timestampFromDate(input) } });
  }
  if (isRecord(input)) {
    const entries = Object.fromEntries(
      Object.entries(input).map(([key, value]) => [key, valueOf(value)]),
    );
    return create(ValueSchema, {
      kind: { case: "mapValue", value: create(ValueMapSchema, { entries }) },
    });
  }
  return create(ValueSchema, {
    kind: { case: "listValue", value: create(ValueListSchema, { values: input.map(valueOf) }) },
  });
};

export const propertiesOf = (input: Properties): Record<string, Value> =>
  Object.fromEntries(Object.entries(input).map(([key, value]) => [key, valueOf(value)]));
