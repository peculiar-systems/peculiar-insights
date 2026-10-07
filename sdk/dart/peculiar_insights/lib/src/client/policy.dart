import "package:freezed_annotation/freezed_annotation.dart";

part "policy.freezed.dart";

@freezed
sealed class ConsentPolicy with _$ConsentPolicy {
  const factory ConsentPolicy.ask() = AskPolicy;

  const factory ConsentPolicy.assumed({
    String? analytics,
    String? diagnostics,
  }) = AssumedPolicy;
}
