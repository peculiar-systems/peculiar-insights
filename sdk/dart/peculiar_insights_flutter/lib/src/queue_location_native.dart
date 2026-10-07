import "package:path_provider/path_provider.dart";
import "package:peculiar_insights/peculiar_insights.dart";

Future<Storage> openStorage({
  required Uri? sqlite3Wasm,
  required Uri? driftWorker,
}) async {
  final directory = await getApplicationSupportDirectory();
  return DriftStorage.native("${directory.path}/peculiar_insights.sqlite");
}
