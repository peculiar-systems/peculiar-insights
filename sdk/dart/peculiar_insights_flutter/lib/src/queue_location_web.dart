import "package:peculiar_insights/peculiar_insights.dart";

Future<Storage> openStorage({
  required Uri? sqlite3Wasm,
  required Uri? driftWorker,
}) async {
  if (sqlite3Wasm == null || driftWorker == null) {
    return MemoryStorage();
  }
  return DriftStorage.web(sqlite3Wasm: sqlite3Wasm, driftWorker: driftWorker);
}
