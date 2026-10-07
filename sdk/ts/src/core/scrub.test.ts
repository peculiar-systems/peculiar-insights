import assert from "node:assert/strict";
import { test } from "node:test";
import { builtinPatterns, replacement, scrubProperties, scrubber } from "./scrub.ts";
import { propertiesOf } from "./values.ts";

const scrub = scrubber(builtinPatterns);

await test("emails are redacted", () => {
  assert.equal(scrub("contact someone@example.org now"), `contact ${replacement} now`);
});

await test("card numbers are redacted", () => {
  assert.equal(scrub("card 4111 1111 1111 1111 declined"), `card ${replacement} declined`);
});

await test("phone numbers are redacted", () => {
  assert.equal(scrub("call +1 (555) 010-9999"), `call ${replacement}`);
});

await test("ordinary numbers survive", () => {
  assert.equal(scrub("retry 3 of 5 after 250ms"), "retry 3 of 5 after 250ms");
});

await test("app patterns add to the builtins", () => {
  const custom = scrubber([...builtinPatterns, /token-[a-z0-9]+/u]);
  assert.equal(custom("token-abc123 for someone@example.org"), `${replacement} for ${replacement}`);
});

await test("nested string properties are scrubbed", () => {
  const scrubbed = scrubProperties(
    scrub,
    propertiesOf({ note: "mail someone@example.org", nested: { list: ["x@example.org", 1] } }),
  );
  assert.equal(scrubbed["note"]?.kind.value, `mail ${replacement}`);
  const nested = scrubbed["nested"]?.kind;
  const list = nested?.case === "mapValue" ? nested.value.entries["list"]?.kind : undefined;
  const first = list?.case === "listValue" ? list.value.values[0]?.kind.value : undefined;
  assert.equal(first, replacement);
});
