import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:fixnum/fixnum.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:peculiar_insights/captured.dart";
import "package:peculiar_insights/peculiar_insights.dart";

part "native_report.freezed.dart";
part "native_report.g.dart";

final class HexAddress implements JsonConverter<Int64, String> {
  const HexAddress();

  @override
  Int64 fromJson(String json) => Int64.parseHex(json);

  @override
  String toJson(Int64 object) => object.toHexString();
}

@freezed
abstract class NativeImage with _$NativeImage {
  const NativeImage._();

  const factory NativeImage({
    required String name,
    required String identifier,
    @HexAddress() required Int64 loadAddress,
  }) = _NativeImage;

  factory NativeImage.fromJson(Map<String, Object?> json) =>
      _$NativeImageFromJson(json);

  BinaryImage get binaryImage =>
      BinaryImage(name: name, identifier: identifier, loadAddress: loadAddress);
}

@freezed
abstract class NativeFrame with _$NativeFrame {
  const NativeFrame._();

  const factory NativeFrame({
    required String module,
    required String function,
    required String file,
    required int line,
    required bool inApp,
    @HexAddress() Int64? address,
    NativeImage? image,
  }) = _NativeFrame;

  factory NativeFrame.fromJson(Map<String, Object?> json) =>
      _$NativeFrameFromJson(json);

  Frame get frame => Frame(
    moduleName: module,
    function: function,
    file: file,
    line: line,
    column: 0,
    inApp: inApp,
    instructionAddress: address,
    image: image?.binaryImage,
  );
}

@freezed
abstract class NativeReport with _$NativeReport {
  const NativeReport._();

  const factory NativeReport({
    required String id,
    required int timeMillis,
    required String exceptionType,
    required String message,
    required String thread,
    required String appVersion,
    required String appBuild,
    required IList<NativeFrame> frames,
  }) = _NativeReport;

  factory NativeReport.fromJson(Map<String, Object?> json) =>
      _$NativeReportFromJson(json);

  CapturedCrash get captured => CapturedCrash(
    id: id,
    time: DateTime.fromMillisecondsSinceEpoch(timeMillis, isUtc: true),
    exceptionType: exceptionType,
    message: message,
    thread: thread,
    frames: frames.map((frame) => frame.frame).toIList(),
    app: AppInfo(version: appVersion, build: appBuild),
  );
}
