import Flutter

public class PeculiarInsightsFlutterPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    PeculiarCrashInstall()
    FlutterMethodChannel(
      name: "peculiar_insights_flutter/native_crashes",
      binaryMessenger: registrar.messenger()
    ).setMethodCallHandler(handle)
  }

  private static func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "configure", let arguments = call.arguments as? [String: Any] else {
      result(FlutterMethodNotImplemented)
      return
    }
    PeculiarCrashConfigure(
      arguments["directory"] as? String ?? "",
      arguments["appVersion"] as? String ?? "",
      arguments["appBuild"] as? String ?? "",
      arguments["capture"] as? Bool ?? false
    )
    result(nil)
  }
}
