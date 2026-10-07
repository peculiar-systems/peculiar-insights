import "package:freezed_annotation/freezed_annotation.dart";

part "diagnostic.freezed.dart";

@freezed
sealed class Diagnostic with _$Diagnostic {
  const factory Diagnostic.rejected({
    required String id,
    required String outcome,
    required String reason,
  }) = RejectedDiagnostic;

  const factory Diagnostic.transportFailed({
    required int code,
    required String message,
    required bool willRetry,
  }) = TransportFailedDiagnostic;

  const factory Diagnostic.dropped({
    required int count,
    required String reason,
  }) = DroppedDiagnostic;

  const factory Diagnostic.conversionFailed({
    required String key,
    required String type,
  }) = ConversionFailedDiagnostic;
}
