import "package:drift/drift.dart";
import "package:drift/wasm.dart";

QueryExecutor openNativeExecutor(String path) =>
    throw UnsupportedError("a file-backed queue needs dart:io");

Future<QueryExecutor> openWebExecutor({
  required Uri sqlite3Wasm,
  required Uri driftWorker,
}) async {
  final result = await WasmDatabase.open(
    databaseName: "peculiar_insights",
    sqlite3Uri: sqlite3Wasm,
    driftWorkerUri: driftWorker,
  );
  return result.resolvedExecutor;
}
