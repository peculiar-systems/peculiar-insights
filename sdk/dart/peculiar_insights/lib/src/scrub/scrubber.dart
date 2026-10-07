import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:peculiar_insights/src/model/value.dart";

const redacted = "[redacted]";

final class Scrubber {
  const Scrubber(this.patterns);

  factory Scrubber.standard({Iterable<RegExp> extra = const []}) =>
      Scrubber(IList([..._builtIn, ...extra]));

  static final IList<RegExp> _builtIn = IList([
    RegExp(r"[\w.+-]+@[\w-]+(\.[\w-]+)+"),
    RegExp(r"(?<![\d-])\d(?:[ -]?\d){12,18}(?![\d-])"),
    RegExp(r"(?<![\w.])\+?\d[\d\s().-]{7,}\d(?![\w.])"),
  ]);

  final IList<RegExp> patterns;

  String scrub(String text) => patterns.fold(
    text,
    (current, pattern) => current.replaceAll(pattern, redacted),
  );

  Value scrubValue(Value value) => value.mapText(scrub);

  IMap<String, Value> scrubAll(IMap<String, Value> values) =>
      values.map((key, value) => MapEntry(key, scrubValue(value)));
}
