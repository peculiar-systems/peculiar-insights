import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:peculiar_insights/src/scrub/scrubber.dart";

part "options.freezed.dart";

const sdkVersion = "0.2.0";

@freezed
abstract class AppInfo with _$AppInfo {
  const factory AppInfo({required String version, required String build}) =
      _AppInfo;
}

@freezed
abstract class InsightsOptions with _$InsightsOptions {
  const factory InsightsOptions({
    @Default("dart") String sdkName,
    @Default(Duration(seconds: 10)) Duration flushInterval,
    @Default(100) int batchSize,
    @Default(500) int bufferLimit,
    @Default(Duration(minutes: 30)) Duration sessionTimeout,
    @Default(Duration(seconds: 20)) Duration callTimeout,
    @Default(64) int logLimit,
    @Default(IListConst([])) IList<String> inAppPackages,
    @Default(false) bool privacyControlSignal,
    Scrubber? scrubber,
  }) = _InsightsOptions;
}
