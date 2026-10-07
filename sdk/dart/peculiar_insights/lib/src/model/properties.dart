import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:peculiar_insights/src/model/diagnostic.dart";
import "package:peculiar_insights/src/model/value.dart";

part "properties.freezed.dart";

typedef Properties = Map<String, Object?>;

@freezed
abstract class Converted with _$Converted {
  const Converted._();

  const factory Converted({
    required IMap<String, Value> values,
    required IList<Diagnostic> failures,
  }) = _Converted;

  static const empty = Converted(
    values: IMapConst({}),
    failures: IListConst([]),
  );
}

Converted convertProperties(Properties properties) {
  final values = <String, Value>{};
  final failures = <Diagnostic>[];
  for (final MapEntry(:key, :value) in properties.entries) {
    if (value == null) {
      continue;
    }
    final converted = convertValue(value);
    if (converted == null) {
      failures.add(
        Diagnostic.conversionFailed(
          key: key,
          type: value.runtimeType.toString(),
        ),
      );
    } else {
      values[key] = converted;
    }
  }
  return Converted(values: values.lock, failures: failures.lock);
}

Value? convertValue(Object value) => switch (value) {
  final Value value => value,
  final String text => Value.text(text),
  final int integer => Value.integer(integer),
  final double decimal => Value.decimal(decimal),
  final bool flag => Value.flag(value: flag),
  final DateTime time => Value.time(time),
  final Map<String, Object?> entries => _convertMap(entries),
  final Iterable<Object?> items => _convertList(items),
  _ => null,
};

Value? _convertMap(Map<String, Object?> entries) {
  final converted = convertProperties(entries);
  return converted.failures.isEmpty ? Value.map(converted.values) : null;
}

Value? _convertList(Iterable<Object?> items) {
  final values = <Value>[];
  for (final item in items) {
    if (item == null) {
      return null;
    }
    final converted = convertValue(item);
    if (converted == null) {
      return null;
    }
    values.add(converted);
  }
  return Value.list(values.lock);
}
