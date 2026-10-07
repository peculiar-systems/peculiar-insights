import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:peculiar_insights/src/model/consent.dart";
import "package:peculiar_insights/src/model/item.dart";

part "buffer.freezed.dart";

@freezed
abstract class PendingBuffer with _$PendingBuffer {
  const PendingBuffer._();

  const factory PendingBuffer({
    required int limit,
    @Default(IMapConst({})) IMap<Purpose, IList<Outgoing>> held,
  }) = _PendingBuffer;

  IList<Outgoing> of(Purpose purpose) => held[purpose] ?? const IListConst([]);

  PendingBuffer push(Outgoing item) {
    final grown = of(item.purpose).add(item);
    final bounded = grown.length > limit
        ? grown.sublist(grown.length - limit)
        : grown;
    return copyWith(held: held.add(item.purpose, bounded));
  }

  PendingBuffer drop(Purpose purpose) => copyWith(held: held.remove(purpose));

  int get length => held.values.fold(0, (sum, items) => sum + items.length);
}
