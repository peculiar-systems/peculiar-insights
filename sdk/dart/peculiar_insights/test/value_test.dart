import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:peculiar_insights/internal.dart";
import "package:test/test.dart";

void main() {
  test("each value maps to its proto case", () {
    expect("x".asValue.toProto().hasStringValue(), isTrue);
    expect(1.asValue.toProto().intValue.toInt(), 1);
    expect(1.5.asValue.toProto().doubleValue, 1.5);
    expect(true.asValue.toProto().boolValue, isTrue);
    expect(
      DateTime.utc(2026, 1, 2, 3, 4, 5, 6).asValue.toProto().timeValue.nanos,
      6000000,
    );
    expect(Value.list(IList([1.asValue])).toProto().listValue.values.length, 1);
    expect(
      Value.map(IMap({"k": "v".asValue})).toProto().mapValue.entries["k"],
      isNotNull,
    );
  });

  test("timestamps keep whole seconds", () {
    final stamp = timestampOf(DateTime.utc(2001, 9, 9, 1, 46, 40));
    expect(stamp.seconds.toInt(), 1000000000);
    expect(stamp.nanos, 0);
  });
}
