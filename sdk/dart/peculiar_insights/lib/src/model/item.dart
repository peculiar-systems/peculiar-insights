import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:peculiar_insights/gen/peculiar/insights/v1/ingest.pb.dart"
    as pb;
import "package:peculiar_insights/src/model/consent.dart";
import "package:peculiar_insights/src/model/context.dart";
import "package:peculiar_insights/src/model/crash.dart";
import "package:peculiar_insights/src/model/ids.dart";
import "package:peculiar_insights/src/model/value.dart";

part "item.freezed.dart";

@freezed
abstract class Subject with _$Subject {
  const Subject._();

  const factory Subject({
    required DeviceId device,
    required UserId? user,
    required SessionId session,
  }) = _Subject;

  pb.Subject toProto() => pb.Subject(
    deviceId: device.value,
    userId: user?.value,
    sessionId: session.value,
  );
}

@freezed
sealed class ProfileOperation with _$ProfileOperation {
  const ProfileOperation._();

  const factory ProfileOperation.set(String key, Value value) = SetOperation;
  const factory ProfileOperation.setOnce(String key, Value value) =
      SetOnceOperation;
  const factory ProfileOperation.unset(String key) = UnsetOperation;

  pb.ProfileOperation toProto() => switch (this) {
    SetOperation(:final key, :final value) => pb.ProfileOperation(
      key: key,
      set: value.toProto(),
    ),
    SetOnceOperation(:final key, :final value) => pb.ProfileOperation(
      key: key,
      setOnce: value.toProto(),
    ),
    UnsetOperation(:final key) => pb.ProfileOperation(
      key: key,
      unset: pb.Unset(),
    ),
  };
}

@freezed
sealed class Outgoing with _$Outgoing {
  const Outgoing._();

  const factory Outgoing.event({
    required String id,
    required DateTime time,
    required Subject subject,
    required AppContext context,
    required String name,
    required IMap<String, Value> properties,
  }) = EventItem;

  const factory Outgoing.identify({
    required String id,
    required DateTime time,
    required DeviceId deviceId,
    required UserId userId,
  }) = IdentifyItem;

  const factory Outgoing.profile({
    required String id,
    required DateTime time,
    required DeviceId deviceId,
    required UserId userId,
    required IList<ProfileOperation> operations,
  }) = ProfileItem;

  const factory Outgoing.crash({
    required String id,
    required DateTime time,
    required Subject subject,
    required AppContext context,
    required String exceptionType,
    required String message,
    required IList<Frame> frames,
    required String rawStackTrace,
    required bool fatal,
    required String thread,
    required IMap<String, Value> customKeys,
    required IList<LogLine> logs,
  }) = CrashItem;

  Purpose get purpose => switch (this) {
    CrashItem() => Purpose.diagnostics,
    EventItem() || IdentifyItem() || ProfileItem() => Purpose.analytics,
  };

  bool get isFatal => switch (this) {
    CrashItem(:final fatal) => fatal,
    EventItem() || IdentifyItem() || ProfileItem() => false,
  };

  pb.Item toProto() => switch (this) {
    EventItem(
      :final id,
      :final time,
      :final subject,
      :final context,
      :final name,
      :final properties,
    ) =>
      pb.Item(
        event: pb.Event(
          id: id,
          time: timestampOf(time),
          subject: subject.toProto(),
          context: context.toProto(),
          name: name,
          properties: protoProperties(properties).entries,
        ),
      ),
    IdentifyItem(:final id, :final time, :final deviceId, :final userId) =>
      pb.Item(
        identify: pb.Identify(
          id: id,
          time: timestampOf(time),
          deviceId: deviceId.value,
          userId: userId.value,
        ),
      ),
    ProfileItem(
      :final id,
      :final time,
      :final deviceId,
      :final userId,
      :final operations,
    ) =>
      pb.Item(
        profileUpdate: pb.ProfileUpdate(
          id: id,
          time: timestampOf(time),
          deviceId: deviceId.value,
          userId: userId.value,
          operations: operations.map((o) => o.toProto()),
        ),
      ),
    CrashItem(
      :final id,
      :final time,
      :final subject,
      :final context,
      :final exceptionType,
      :final message,
      :final frames,
      :final rawStackTrace,
      :final fatal,
      :final thread,
      :final customKeys,
      :final logs,
    ) =>
      pb.Item(
        crashReport: pb.CrashReport(
          id: id,
          time: timestampOf(time),
          subject: subject.toProto(),
          context: context.toProto(),
          exceptionType: exceptionType,
          message: message,
          frames: frames.map((f) => f.toProto()),
          rawStackTrace: rawStackTrace,
          fatal: fatal,
          thread: thread,
          customKeys: protoProperties(customKeys).entries,
          logs: logs.map((l) => l.toProto()),
        ),
      ),
  };
}
