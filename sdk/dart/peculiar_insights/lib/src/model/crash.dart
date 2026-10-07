import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:fixnum/fixnum.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:peculiar_insights/gen/peculiar/insights/v1/ingest.pb.dart"
    as pb;
import "package:peculiar_insights/src/client/options.dart";
import "package:peculiar_insights/src/model/value.dart";

part "crash.freezed.dart";

@freezed
abstract class BinaryImage with _$BinaryImage {
  const BinaryImage._();

  const factory BinaryImage({
    required String name,
    required String identifier,
    required Int64 loadAddress,
  }) = _BinaryImage;

  pb.Image toProto() =>
      pb.Image(name: name, identifier: identifier, loadAddress: loadAddress);
}

@freezed
abstract class Frame with _$Frame {
  const Frame._();

  const factory Frame({
    required String moduleName,
    required String function,
    required String file,
    required int line,
    required int column,
    required bool inApp,
    Int64? instructionAddress,
    BinaryImage? image,
  }) = _Frame;

  pb.Frame toProto() => pb.Frame(
    module: moduleName,
    function: function,
    file: file,
    line: line,
    column: column,
    inApp: inApp,
    instructionAddress: instructionAddress,
    image: image?.toProto(),
  );
}

enum LogLevel {
  debug,
  info,
  warning,
  error;

  pb.LogLevel toProto() => switch (this) {
    LogLevel.debug => pb.LogLevel.LOG_LEVEL_DEBUG,
    LogLevel.info => pb.LogLevel.LOG_LEVEL_INFO,
    LogLevel.warning => pb.LogLevel.LOG_LEVEL_WARNING,
    LogLevel.error => pb.LogLevel.LOG_LEVEL_ERROR,
  };
}

@freezed
abstract class LogLine with _$LogLine {
  const LogLine._();

  const factory LogLine({
    required DateTime time,
    required LogLevel level,
    required String message,
  }) = _LogLine;

  pb.LogLine toProto() => pb.LogLine(
    time: timestampOf(time),
    level: level.toProto(),
    message: message,
  );
}

@freezed
abstract class CapturedCrash with _$CapturedCrash {
  const factory CapturedCrash({
    required String id,
    required DateTime time,
    required String exceptionType,
    required String message,
    required String thread,
    required IList<Frame> frames,
    required AppInfo app,
  }) = _CapturedCrash;
}

IList<LogLine> appendLog(IList<LogLine> logs, LogLine line, int limit) {
  final grown = logs.add(line);
  return grown.length > limit ? grown.sublist(grown.length - limit) : grown;
}
