import "package:peculiar_insights/peculiar_insights.dart";

Future<Storage> openStorage({
  required Uri? sqlite3Wasm,
  required Uri? driftWorker,
}) async => MemoryStorage();
