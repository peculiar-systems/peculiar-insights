import "dart:convert";
import "dart:io";

import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter/services.dart";
import "package:peculiar_insights/peculiar_insights.dart";
import "package:peculiar_insights_flutter/src/native_crash/model/native_report.dart";

final class NativeCrashes {
  const NativeCrashes({
    required this.directory,
    required this.app,
    this.channel = const MethodChannel(channelName),
  });

  static const channelName = "peculiar_insights_flutter/native_crashes";

  final Directory directory;
  final AppInfo app;
  final MethodChannel channel;

  Future<Stream<DeviceChange>> attach(Insights insights) async {
    final consent = insights.consent.status;
    await _steer(consent);
    if (consent.permits(Purpose.diagnostics)) {
      await _deliverWaiting(insights);
    } else {
      await _clear();
    }
    return insights.changes.asyncMap(_changed);
  }

  Future<DeviceChange> _changed(DeviceChange change) async {
    switch (change) {
      case ConsentedChange(:final consent):
        await _steer(consent);
        if (!consent.permits(Purpose.diagnostics)) {
          await _clear();
        }
      case ErasedChange():
        await _clear();
    }
    return change;
  }

  Future<void> _steer(Consent consent) async {
    final capture = consent.permits(Purpose.diagnostics);
    if (capture) {
      directory.createSync(recursive: true);
    }
    await channel.invokeMethod<void>("configure", {
      "directory": directory.path,
      "capture": capture,
      "appVersion": app.version,
      "appBuild": app.build,
    });
  }

  Future<IList<File>> _waiting() async => directory.existsSync()
      ? (await directory
                .list()
                .where((entry) => entry is File)
                .cast<File>()
                .toList())
            .toIList()
      : const IListConst([]);

  Future<void> _deliverWaiting(Insights insights) async {
    final reports = (await _waiting()).where(
      (file) => file.path.endsWith(".json"),
    );
    for (final file in reports) {
      await _deliver(insights, file);
    }
  }

  Future<void> _deliver(Insights insights, File file) async {
    final report = await _read(file);
    if (report != null) {
      await insights.recordCaptured(report.captured);
    }
    await _remove(file);
  }

  Future<void> _remove(File file) async {
    try {
      await file.delete();
    } on PathNotFoundException catch (_) {
      return;
    }
  }

  Future<NativeReport?> _read(File file) async {
    try {
      return switch (jsonDecode(
        utf8.decode(file.readAsBytesSync(), allowMalformed: true),
      )) {
        final Map<String, Object?> json => NativeReport.fromJson(json),
        _ => null,
      };
    } on Object catch (_) {
      return null;
    }
  }

  Future<void> _clear() async {
    for (final file in await _waiting()) {
      await _remove(file);
    }
  }
}
