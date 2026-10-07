import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:peculiar_insights/src/consent/buffer.dart";
import "package:peculiar_insights/src/model/consent.dart";
import "package:peculiar_insights/src/model/crash.dart";
import "package:peculiar_insights/src/model/ids.dart";
import "package:peculiar_insights/src/session/session.dart";

part "state.freezed.dart";

@freezed
abstract class ClientState with _$ClientState {
  const ClientState._();

  const factory ClientState({
    required DeviceId deviceId,
    required bool devicePersisted,
    required UserId? userId,
    required Consent consent,
    required Session session,
    required PendingBuffer buffer,
    @Default(IListConst([])) IList<LogLine> logs,
  }) = _ClientState;
}
