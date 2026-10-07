import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:peculiar_insights/internal.dart";
import "package:peculiar_insights/peculiar_insights.dart";
import "package:test/test.dart";

void main() {
  final scrubber = Scrubber.standard();

  test("emails are redacted", () {
    expect(
      scrubber.scrub("write to someone@example.org today"),
      "write to $redacted today",
    );
  });

  test("card numbers are redacted", () {
    expect(
      scrubber.scrub("card 4111 1111 1111 1111 declined"),
      "card $redacted declined",
    );
  });

  test("phone numbers are redacted", () {
    expect(scrubber.scrub("call +1 555 010 9999 now"), "call $redacted now");
  });

  test("plain numbers survive", () {
    expect(scrubber.scrub("order 42 of 100"), "order 42 of 100");
  });

  test("nested values are scrubbed", () {
    const value = Value.map(
      IMapConst({"who": Value.text("a@example.org"), "n": Value.integer(3)}),
    );
    expect(
      scrubber.scrubValue(value),
      const Value.map(
        IMapConst({"who": Value.text(redacted), "n": Value.integer(3)}),
      ),
    );
  });

  test("extra patterns apply", () {
    final custom = Scrubber.standard(extra: [RegExp("secret")]);
    expect(custom.scrub("a secret thing"), "a $redacted thing");
  });
}
