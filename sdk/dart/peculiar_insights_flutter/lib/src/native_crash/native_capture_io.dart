import "dart:async";
import "dart:io";

import "package:path_provider/path_provider.dart";
import "package:peculiar_insights/peculiar_insights.dart";
import "package:peculiar_insights_flutter/src/native_crash/native_crashes.dart";

final class NativeCapture {
  const NativeCapture();

  Future<void> attach(Insights insights, AppInfo app) async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return;
    }
    final support = await getApplicationSupportDirectory();
    final handled = await NativeCrashes(
      directory: Directory("${support.path}/peculiar_insights_crashes"),
      app: app,
    ).attach(insights);
    unawaited(handled.drain<void>());
  }
}
