import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:peculiar_insights/src/model/consent.dart";
import "package:peculiar_insights/src/queue/storage.dart";

final class MemoryStorage implements Storage {
  MemoryStorage();

  IList<QueueRow> _rows = const IListConst([]);
  IMap<String, String> _state = const IMapConst({});

  IList<QueueRow> get rows => _rows;

  @override
  Future<void> append(IList<QueueRow> rows) async {
    _rows = _rows.addAll(rows);
  }

  @override
  Future<IList<QueueRow>> peek(int limit) async => _rows.take(limit).toIList();

  @override
  Future<void> remove(IList<String> ids) async {
    final gone = ids.toISet();
    _rows = _rows.where((row) => !gone.contains(row.id)).toIList();
  }

  @override
  Future<void> removePurpose(Purpose purpose) async {
    _rows = _rows.where((row) => row.purpose != purpose).toIList();
  }

  @override
  Future<void> clearQueue() async {
    _rows = const IListConst([]);
  }

  @override
  Future<String?> readState(String key) async => _state[key];

  @override
  Future<void> writeState(String key, String value) async {
    _state = _state.add(key, value);
  }

  @override
  Future<void> deleteState(String key) async {
    _state = _state.remove(key);
  }

  @override
  Future<void> close() async {}
}
