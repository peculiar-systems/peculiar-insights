import "dart:typed_data";

import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:peculiar_insights/src/model/consent.dart";

part "storage.freezed.dart";

enum QueueKind { publish, consent, erasure }

@freezed
abstract class QueueRow with _$QueueRow {
  const factory QueueRow({
    required String id,
    required QueueKind kind,
    required Purpose purpose,
    required Uint8List payload,
    required int createdAt,
    Uint8List? consent,
  }) = _QueueRow;
}

abstract interface class Storage {
  Future<void> append(IList<QueueRow> rows);

  Future<IList<QueueRow>> peek(int limit);

  Future<void> remove(IList<String> ids);

  Future<void> removePurpose(Purpose purpose);

  Future<void> clearQueue();

  Future<String?> readState(String key);

  Future<void> writeState(String key, String value);

  Future<void> deleteState(String key);

  Future<void> close();
}

abstract final class StateKeys {
  static const deviceId = "device_id";
  static const userId = "user_id";
  static const consent = "consent";
}
