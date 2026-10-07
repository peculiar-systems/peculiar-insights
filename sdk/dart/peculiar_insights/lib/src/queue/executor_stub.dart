import "package:drift/drift.dart";

QueryExecutor openNativeExecutor(String path) =>
    throw UnsupportedError("a file-backed queue needs dart:io");

Future<QueryExecutor> openWebExecutor({
  required Uri sqlite3Wasm,
  required Uri driftWorker,
}) => throw UnsupportedError("a browser-backed queue needs the web platform");
