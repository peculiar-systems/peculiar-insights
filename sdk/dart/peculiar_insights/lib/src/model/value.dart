import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:fixnum/fixnum.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:peculiar_insights/gen/peculiar/insights/v1/common.pb.dart"
    as pb;
import "package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart"
    as pb;

part "value.freezed.dart";

@freezed
sealed class Value with _$Value {
  const Value._();

  const factory Value.text(String value) = TextValue;
  const factory Value.integer(int value) = IntegerValue;
  const factory Value.decimal(double value) = DecimalValue;
  const factory Value.flag({required bool value}) = FlagValue;
  const factory Value.time(DateTime value) = TimeValue;
  const factory Value.list(IList<Value> values) = ListValue;
  const factory Value.map(IMap<String, Value> entries) = MapValue;

  pb.Value toProto() => switch (this) {
    TextValue(:final value) => pb.Value(stringValue: value),
    IntegerValue(:final value) => pb.Value(intValue: Int64(value)),
    DecimalValue(:final value) => pb.Value(doubleValue: value),
    FlagValue(:final value) => pb.Value(boolValue: value),
    TimeValue(:final value) => pb.Value(timeValue: timestampOf(value)),
    ListValue(:final values) => pb.Value(
      listValue: pb.ValueList(values: values.map((v) => v.toProto())),
    ),
    MapValue(:final entries) => pb.Value(
      mapValue: pb.ValueMap(entries: protoProperties(entries).entries),
    ),
  };

  Value mapText(String Function(String text) transform) => switch (this) {
    TextValue(:final value) => Value.text(transform(value)),
    ListValue(:final values) => Value.list(
      values.map((v) => v.mapText(transform)).toIList(),
    ),
    MapValue(:final entries) => Value.map(
      entries.map((k, v) => MapEntry(k, v.mapText(transform))),
    ),
    IntegerValue() || DecimalValue() || FlagValue() || TimeValue() => this,
  };
}

pb.Timestamp timestampOf(DateTime time) {
  final micros = time.toUtc().microsecondsSinceEpoch;
  final seconds = micros ~/ Duration.microsecondsPerSecond;
  final nanos = (micros - seconds * Duration.microsecondsPerSecond) * 1000;
  return pb.Timestamp(seconds: Int64(seconds), nanos: nanos);
}

extension TextAsValue on String {
  Value get asValue => Value.text(this);
}

extension IntegerAsValue on int {
  Value get asValue => Value.integer(this);
}

extension DecimalAsValue on double {
  Value get asValue => Value.decimal(this);
}

extension FlagAsValue on bool {
  Value get asValue => Value.flag(value: this);
}

extension TimeAsValue on DateTime {
  Value get asValue => Value.time(this);
}

IMap<String, pb.Value> protoProperties(IMap<String, Value> properties) =>
    properties.map((key, value) => MapEntry(key, value.toProto()));
