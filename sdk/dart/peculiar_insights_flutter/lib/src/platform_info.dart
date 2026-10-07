import "dart:ui";

import "package:device_info_plus/device_info_plus.dart";
import "package:flutter/foundation.dart";
import "package:peculiar_insights/peculiar_insights.dart";

Future<PlatformInfo> readPlatformInfo() async {
  final view = PlatformDispatcher.instance.views.firstOrNull;
  final size = view?.physicalSize ?? Size.zero;
  final locale = PlatformDispatcher.instance.locale.toLanguageTag();
  final timezone = DateTime.now().timeZoneName;
  final device = await _describeDevice();
  return PlatformInfo(
    platform: _platform(),
    osName: device.osName,
    osVersion: device.osVersion,
    deviceModel: device.model,
    locale: locale,
    timezone: timezone,
    screenWidth: size.width.round(),
    screenHeight: size.height.round(),
  );
}

AppPlatform _platform() {
  if (kIsWeb) {
    return AppPlatform.web;
  }
  return switch (defaultTargetPlatform) {
    TargetPlatform.iOS => AppPlatform.ios,
    TargetPlatform.android => AppPlatform.android,
    TargetPlatform.macOS => AppPlatform.macos,
    TargetPlatform.windows => AppPlatform.windows,
    TargetPlatform.linux => AppPlatform.linux,
    TargetPlatform.fuchsia => AppPlatform.unknown,
  };
}

typedef _Device = ({String osName, String osVersion, String model});

Future<_Device> _describeDevice() async {
  final plugin = DeviceInfoPlugin();
  if (kIsWeb) {
    final info = await plugin.webBrowserInfo;
    return (
      osName: info.browserName.name,
      osVersion: info.appVersion ?? "",
      model: info.platform ?? "",
    );
  }
  return switch (defaultTargetPlatform) {
    TargetPlatform.iOS => _ios(await plugin.iosInfo),
    TargetPlatform.android => _android(await plugin.androidInfo),
    TargetPlatform.macOS => _macos(await plugin.macOsInfo),
    TargetPlatform.windows => _windows(await plugin.windowsInfo),
    TargetPlatform.linux => _linux(await plugin.linuxInfo),
    TargetPlatform.fuchsia => (osName: "fuchsia", osVersion: "", model: ""),
  };
}

_Device _ios(IosDeviceInfo info) => (
  osName: info.systemName,
  osVersion: info.systemVersion,
  model: info.utsname.machine,
);

_Device _android(AndroidDeviceInfo info) =>
    (osName: "Android", osVersion: info.version.release, model: info.model);

_Device _macos(MacOsDeviceInfo info) => (
  osName: "macOS",
  osVersion: "${info.majorVersion}.${info.minorVersion}.${info.patchVersion}",
  model: info.model,
);

_Device _windows(WindowsDeviceInfo info) => (
  osName: "Windows",
  osVersion: info.displayVersion,
  model: info.productName,
);

_Device _linux(LinuxDeviceInfo info) =>
    (osName: info.name, osVersion: info.version ?? "", model: info.prettyName);
