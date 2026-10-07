import { create } from "@bufbuild/protobuf";
import { FrameSchema, type Frame } from "../gen/peculiar/insights/v1/ingest_pb.js";

const v8Located = /^\s*at (?:async )?(?:new )?(.+?) \((.+?):(\d+):(\d+)\)$/u;
const v8Bare = /^\s*at (?:async )?(.+?):(\d+):(\d+)$/u;
const gecko = /^(.*?)@(.+?):(\d+):(\d+)$/u;

const inApp = (file: string): boolean =>
  !file.includes("node_modules") && !file.startsWith("node:");

const frame = (fn: string, file: string, line: string, column: string): Frame =>
  create(FrameSchema, {
    module: "",
    function: fn,
    file,
    line: Number(line),
    column: Number(column),
    inApp: inApp(file),
  });

const parseLine = (line: string): Frame | undefined => {
  const located = v8Located.exec(line);
  if (located !== null) {
    const [, fn = "", file = "", row = "0", column = "0"] = located;
    return frame(fn, file, row, column);
  }
  const bare = v8Bare.exec(line);
  if (bare !== null) {
    const [, file = "", row = "0", column = "0"] = bare;
    return frame("", file, row, column);
  }
  const mozilla = gecko.exec(line);
  if (mozilla !== null) {
    const [, fn = "", file = "", row = "0", column = "0"] = mozilla;
    return frame(fn, file, row, column);
  }
  return undefined;
};

export const parseStack = (stack: string): Frame[] =>
  stack.split("\n").flatMap((line) => {
    const parsed = parseLine(line);
    return parsed === undefined ? [] : [parsed];
  });

export type Described = {
  readonly exceptionType: string;
  readonly message: string;
  readonly stack: string;
};

export const describeError = (error: unknown): Described => {
  if (error instanceof Error) {
    return { exceptionType: error.name, message: error.message, stack: error.stack ?? "" };
  }
  if (typeof error === "string") {
    return { exceptionType: "Error", message: error, stack: "" };
  }
  return { exceptionType: "Error", message: String(error), stack: "" };
};
