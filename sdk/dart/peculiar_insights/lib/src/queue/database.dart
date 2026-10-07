import "package:drift/drift.dart";

part "database.g.dart";

@DriftDatabase(include: {"storage.drift"})
final class QueueDatabase extends _$QueueDatabase {
  QueueDatabase(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.addColumn(queueItem, queueItem.consent);
      }
    },
  );
}
