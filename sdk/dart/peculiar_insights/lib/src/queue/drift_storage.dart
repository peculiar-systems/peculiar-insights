import "package:drift/drift.dart";
import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:peculiar_insights/src/model/consent.dart";
import "package:peculiar_insights/src/queue/database.dart";
import "package:peculiar_insights/src/queue/executor_stub.dart"
    if (dart.library.io) "package:peculiar_insights/src/queue/executor_native.dart"
    if (dart.library.js_interop) "package:peculiar_insights/src/queue/executor_web.dart";
import "package:peculiar_insights/src/queue/storage.dart";

final class DriftStorage implements Storage {
  DriftStorage._(this._database);

  factory DriftStorage.native(String path) =>
      DriftStorage._(QueueDatabase(openNativeExecutor(path)));

  factory DriftStorage.executor(QueryExecutor executor) =>
      DriftStorage._(QueueDatabase(executor));

  static Future<DriftStorage> web({
    required Uri sqlite3Wasm,
    required Uri driftWorker,
  }) async => DriftStorage._(
    QueueDatabase(
      await openWebExecutor(sqlite3Wasm: sqlite3Wasm, driftWorker: driftWorker),
    ),
  );

  final QueueDatabase _database;

  @override
  Future<void> append(IList<QueueRow> rows) => _database.batch(
    (batch) => batch.insertAll(
      _database.queueItem,
      rows.map(
        (row) => QueueItemCompanion.insert(
          id: row.id,
          kind: row.kind.name,
          purpose: row.purpose.name,
          payload: row.payload,
          createdAt: row.createdAt,
          consent: Value(row.consent),
        ),
      ),
    ),
  );

  @override
  Future<IList<QueueRow>> peek(int limit) async {
    final rows = await _database.peekRows(limit).get();
    return rows
        .map(
          (row) => QueueRow(
            id: row.id,
            kind: QueueKind.values.byName(row.kind),
            purpose: Purpose.values.byName(row.purpose),
            payload: row.payload,
            createdAt: row.createdAt,
            consent: row.consent,
          ),
        )
        .toIList();
  }

  @override
  Future<void> remove(IList<String> ids) async {
    if (ids.isEmpty) {
      return;
    }
    await _database.removeRows(ids.unlock);
  }

  @override
  Future<void> removePurpose(Purpose purpose) async {
    await _database.removePurposeRows(purpose.name);
  }

  @override
  Future<void> clearQueue() async {
    await _database.clearRows();
  }

  @override
  Future<String?> readState(String key) =>
      _database.readEntry(key).getSingleOrNull();

  @override
  Future<void> writeState(String key, String value) async {
    await _database.writeEntry(key, value);
  }

  @override
  Future<void> deleteState(String key) async {
    await _database.deleteEntry(key);
  }

  @override
  Future<void> close() => _database.close();
}
