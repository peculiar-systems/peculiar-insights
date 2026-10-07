import "package:freezed_annotation/freezed_annotation.dart";
import "package:peculiar_insights/gen/peculiar/insights/v1/common.pb.dart"
    as pb;

part "context.freezed.dart";

enum AppPlatform {
  ios,
  android,
  macos,
  windows,
  linux,
  web,
  server,
  unknown;

  pb.Platform toProto() => switch (this) {
    AppPlatform.ios => pb.Platform.PLATFORM_IOS,
    AppPlatform.android => pb.Platform.PLATFORM_ANDROID,
    AppPlatform.macos => pb.Platform.PLATFORM_MACOS,
    AppPlatform.windows => pb.Platform.PLATFORM_WINDOWS,
    AppPlatform.linux => pb.Platform.PLATFORM_LINUX,
    AppPlatform.web => pb.Platform.PLATFORM_WEB,
    AppPlatform.server => pb.Platform.PLATFORM_SERVER,
    AppPlatform.unknown => pb.Platform.PLATFORM_UNSPECIFIED,
  };
}

@freezed
abstract class PlatformInfo with _$PlatformInfo {
  const PlatformInfo._();

  const factory PlatformInfo({
    required AppPlatform platform,
    required String osName,
    required String osVersion,
    required String deviceModel,
    required String locale,
    required String timezone,
    required int screenWidth,
    required int screenHeight,
  }) = _PlatformInfo;

  static const unknown = PlatformInfo(
    platform: AppPlatform.unknown,
    osName: "",
    osVersion: "",
    deviceModel: "",
    locale: "",
    timezone: "",
    screenWidth: 0,
    screenHeight: 0,
  );
}

@freezed
abstract class AppContext with _$AppContext {
  const AppContext._();

  const factory AppContext({
    required String sdkName,
    required String sdkVersion,
    required String appVersion,
    required String appBuild,
    required PlatformInfo platform,
  }) = _AppContext;

  pb.Context toProto() => pb.Context(
    sdkName: sdkName,
    sdkVersion: sdkVersion,
    appVersion: appVersion,
    appBuild: appBuild,
    platform: platform.platform.toProto(),
    osName: platform.osName,
    osVersion: platform.osVersion,
    deviceModel: platform.deviceModel,
    locale: platform.locale,
    timezone: platform.timezone,
    screenWidth: platform.screenWidth,
    screenHeight: platform.screenHeight,
  );
}
