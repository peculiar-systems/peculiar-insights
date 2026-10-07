import assert from "node:assert/strict";
import { test } from "node:test";
import { describeError, parseStack } from "./stack.ts";

await test("v8 frames are parsed", () => {
  const stack = [
    "TypeError: boom",
    "    at handle (https://app.example.org/assets/app.js:10:15)",
    "    at async run (https://app.example.org/assets/app.js:20:3)",
    "    at https://app.example.org/assets/vendor.js:1:2",
    "    at new Thing (node_modules/lib/index.js:5:6)",
  ].join("\n");
  const frames = parseStack(stack);
  assert.deepEqual(
    frames.map((frame) => [frame.function, frame.file, frame.line, frame.column, frame.inApp]),
    [
      ["handle", "https://app.example.org/assets/app.js", 10, 15, true],
      ["run", "https://app.example.org/assets/app.js", 20, 3, true],
      ["", "https://app.example.org/assets/vendor.js", 1, 2, true],
      ["Thing", "node_modules/lib/index.js", 5, 6, false],
    ],
  );
});

await test("gecko frames are parsed", () => {
  const stack = [
    "handle@https://app.example.org/app.js:10:15",
    "@https://app.example.org/app.js:20:3",
  ].join("\n");
  assert.deepEqual(
    parseStack(stack).map((frame) => [frame.function, frame.line]),
    [
      ["handle", 10],
      ["", 20],
    ],
  );
});

await test("errors and non-errors are described", () => {
  const error = new RangeError("out of range");
  const described = describeError(error);
  assert.equal(described.exceptionType, "RangeError");
  assert.equal(described.message, "out of range");
  assert.ok(described.stack.length > 0);
  assert.deepEqual(describeError("plain"), { exceptionType: "Error", message: "plain", stack: "" });
  assert.equal(describeError(42).message, "42");
});
