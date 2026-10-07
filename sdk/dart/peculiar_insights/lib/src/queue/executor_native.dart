import "dart:io";

import "package:drift/drift.dart";
import "package:drift/native.dart";

QueryExecutor openNativeExecutor(String path) =>
    NativeDatabase.createInBackground(File(path));

Future<QueryExecutor> openWebExecutor({
  required Uri sqlite3Wasm,
  required Uri driftWorker,
}) => throw UnsupportedError("a browser-backed queue needs the web platform");
