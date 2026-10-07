import "dart:async";
import "dart:isolate";

import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter/foundation.dart";
import "package:flutter/widgets.dart";
import "package:package_info_plus/package_info_plus.dart";
import "package:peculiar_insights/lifecycle.dart";
import "package:peculiar_insights/peculiar_insights.dart";
import "package:peculiar_insights_flutter/src/native_crash/native_capture_stub.dart"
    if (dart.library.io) "package:peculiar_insights_flutter/src/native_crash/native_capture_io.dart";
import "package:peculiar_insights_flutter/src/platform_info.dart";
import "package:peculiar_insights_flutter/src/privacy_control_stub.dart"
    if (dart.library.js_interop) "package:peculiar_insights_flutter/src/privacy_control_web.dart";
import "package:peculiar_insights_flutter/src/queue_location_stub.dart"
    if (dart.library.io) "package:peculiar_insights_flutter/src/queue_location_native.dart"
    if (dart.library.js_interop) "package:peculiar_insights_flutter/src/queue_location_web.dart";

extension type const FlutterInsights._(Insights insights) implements Insights {
  static Future<FlutterInsights> start({
    required Uri url,
    required String key,
    required ConsentPolicy consent,
    InsightsOptions options = const InsightsOptions(),
    Iterable<String> inAppPackages = const [],
    bool trackAppLifecycle = false,
    Uri? sqlite3Wasm,
    Uri? driftWorker,
  }) async {
    WidgetsFlutterBinding.ensureInitialized();
    final package = await PackageInfo.fromPlatform();
    final app = AppInfo(version: package.version, build: package.buildNumber);
    final insights = await Insights.start(
      url: url,
      key: key,
      consent: consent,
      app: app,
      storage: await openStorage(
        sqlite3Wasm: sqlite3Wasm,
        driftWorker: driftWorker,
      ),
      platform: await readPlatformInfo(),
      options: options.copyWith(
        sdkName: "flutter",
        inAppPackages: inAppPackages.toIList(),
        privacyControlSignal: kIsWeb && globalPrivacyControl(),
      ),
    );
    final lifecycle = AppLifecycle(insights);
    AppLifecycleListener(
      onPause: () => _paused(insights, lifecycle, trackAppLifecycle),
      onHide: () => _paused(insights, lifecycle, trackAppLifecycle),
      onResume: () => _resumed(insights, lifecycle, trackAppLifecycle),
      onShow: () => _resumed(insights, lifecycle, trackAppLifecycle),
    );
    _installErrorCapture(insights.tracker);
    await const NativeCapture().attach(insights, app);
    return FlutterInsights._(insights);
  }

  static void _paused(Insights insights, AppLifecycle lifecycle, bool track) {
    if (track) {
      unawaited(insights.tracker.track("app_backgrounded"));
    }
    lifecycle.paused();
    unawaited(insights.flush());
  }

  static void _resumed(Insights insights, AppLifecycle lifecycle, bool track) {
    lifecycle.resumed();
    if (track) {
      unawaited(insights.tracker.track("app_foregrounded"));
    }
  }

  static void _installErrorCapture(Tracker tracker) {
    final previousFlutter = FlutterError.onError;
    FlutterError.onError = (details) {
      unawaited(
        tracker.recordError(
          details.exception,
          details.stack ?? StackTrace.empty,
          thread: details.library ?? "flutter",
        ),
      );
      previousFlutter?.call(details);
    };
    final previousPlatform = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (error, stack) {
      unawaited(tracker.recordError(error, stack, fatal: true));
      return previousPlatform?.call(error, stack) ?? true;
    };
    final port = RawReceivePort((Object? message) {
      if (message case [final Object error, final String trace]) {
        unawaited(
          tracker.recordError(
            error,
            StackTrace.fromString(trace),
            fatal: true,
            thread: "isolate",
          ),
        );
      }
    });
    Isolate.current.addErrorListener(port.sendPort);
  }
}

final class InsightsNavigatorObserver extends NavigatorObserver {
  InsightsNavigatorObserver(this.insights);

  final Insights insights;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _viewed(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null) {
      _viewed(previousRoute);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) {
      _viewed(newRoute);
    }
  }

  void _viewed(Route<dynamic> route) {
    final name = route.settings.name;
    if (name != null) {
      unawaited(insights.tracker.track("screen_viewed", {"screen": name}));
    }
  }
}
