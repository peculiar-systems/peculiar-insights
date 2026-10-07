import "package:freezed_annotation/freezed_annotation.dart";

part "session.freezed.dart";

@freezed
abstract class Session with _$Session {
  const Session._();

  const factory Session({required String id, required DateTime lastActivity}) =
      _Session;

  Session touched({
    required DateTime now,
    required Duration timeout,
    required String Function() newId,
  }) => now.difference(lastActivity) > timeout
      ? Session(id: newId(), lastActivity: now)
      : copyWith(lastActivity: now);
}
