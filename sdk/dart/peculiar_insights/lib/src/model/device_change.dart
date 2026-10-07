import "package:freezed_annotation/freezed_annotation.dart";
import "package:peculiar_insights/src/model/consent.dart";

part "device_change.freezed.dart";

@freezed
sealed class DeviceChange with _$DeviceChange {
  const factory DeviceChange.consented(Consent consent) = ConsentedChange;

  const factory DeviceChange.erased() = ErasedChange;
}
