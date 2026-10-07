import "dart:async";
import "dart:typed_data";

import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:grpc/grpc.dart";
import "package:peculiar_insights/gen/peculiar/insights/v1/common.pb.dart"
    as pb;
import "package:peculiar_insights/gen/peculiar/insights/v1/ingest.pb.dart"
    as pb;
import "package:peculiar_insights/src/model/consent.dart";
import "package:peculiar_insights/src/model/diagnostic.dart";
import "package:peculiar_insights/src/model/value.dart";
import "package:peculiar_insights/src/queue/storage.dart";
import "package:peculiar_insights/src/transport/backoff.dart";
import "package:peculiar_insights/src/transport/transport.dart";

typedef Emit = void Function(Diagnostic diagnostic);

final class Dispatcher {
  Dispatcher({
    required Storage storage,
    required Transport transport,
    required DateTime Function() now,
    required int batchSize,
    required Consent Function() consent,
    required Emit emit,
  }) : _storage = storage,
       _transport = transport,
       _now = now,
       _batchSize = batchSize,
       _consent = consent,
       _emit = emit;

  final Storage _storage;
  final Transport _transport;
  final DateTime Function() _now;
  final int _batchSize;
  final Consent Function() _consent;
  final Emit _emit;

  Future<void> _chain = Future.value();
  Pace _pace = steadyPace;
  Timer? _retry;

  int get attempt => _pace.attempt;

  Future<void> flush() {
    final next = _chain.then((_) => _drain());
    _chain = next.then((_) {}, onError: (_) {});
    return next;
  }

  Future<void> _drain() async {
    while (!_pace.holds(_now)) {
      final rows = await _storage.peek(_batchSize);
      if (rows.isEmpty) {
        return;
      }
      final first = rows.first;
      final chunk = rows
          .takeWhile(
            (row) =>
                row.kind == first.kind && sameBytes(row.consent, first.consent),
          )
          .toIList();
      if (!await _send(chunk)) {
        return;
      }
    }
  }

  Future<bool> _send(IList<QueueRow> chunk) async {
    final ids = chunk.map((row) => row.id).toIList();
    try {
      await switch (chunk.first.kind) {
        QueueKind.publish => _publish(chunk),
        QueueKind.consent => _consents(chunk),
        QueueKind.erasure => _erasures(chunk),
      };
      await _storage.remove(ids);
      _pace = steadyPace;
      return true;
    } on GrpcError catch (error) {
      final outcome = classify(error.code);
      _emit(
        Diagnostic.transportFailed(
          code: error.code,
          message: error.message ?? "",
          willRetry: outcome == FailureClass.retry,
        ),
      );
      switch (outcome) {
        case FailureClass.retry:
          _scheduleRetry(error);
          return false;
        case FailureClass.poison:
          await _storage.remove(ids);
          _emit(
            Diagnostic.dropped(
              count: ids.length,
              reason: error.message ?? "rejected by the server",
            ),
          );
          return true;
        case FailureClass.surface:
          return false;
      }
    }
  }

  Future<void> _publish(IList<QueueRow> chunk) async {
    final stored = chunk.first.consent;
    final response = await _transport.publish(
      pb.PublishRequest(
        sentAt: timestampOf(_now()),
        consent: stored == null
            ? _consent().toProto()
            : pb.ConsentSnapshot.fromBuffer(stored),
        items: chunk.map((row) => pb.Item.fromBuffer(row.payload)),
      ),
    );
    for (final outcome in response.outcomes) {
      if (outcome.outcome != pb.Outcome.OUTCOME_ACCEPTED &&
          outcome.outcome != pb.Outcome.OUTCOME_DUPLICATE) {
        _emit(
          Diagnostic.rejected(
            id: outcome.id,
            outcome: outcome.outcome.name,
            reason: outcome.reason,
          ),
        );
      }
    }
  }

  Future<void> _consents(IList<QueueRow> chunk) async {
    for (final row in chunk) {
      await _transport.recordConsent(
        pb.RecordConsentRequest.fromBuffer(row.payload),
      );
    }
  }

  Future<void> _erasures(IList<QueueRow> chunk) async {
    for (final row in chunk) {
      await _transport.requestErasure(
        pb.RequestErasureRequest.fromBuffer(row.payload),
      );
    }
  }

  void _scheduleRetry(GrpcError error) {
    if (error.code == StatusCode.resourceExhausted) {
      final delay = retryPushback(error.trailers) ?? _pace.throttleFallback;
      _pace = _pace.throttledUntil(_now().add(delay));
      _arm(delay);
    } else {
      _arm(backoffDelay(_pace.attempt));
      _pace = _pace.failed();
    }
  }

  void _arm(Duration delay) {
    _retry?.cancel();
    _retry = Timer(delay, () {
      _pace = _pace.released();
      unawaited(flush());
    });
  }

  void dispose() {
    _retry?.cancel();
  }
}

bool sameBytes(Uint8List? left, Uint8List? right) {
  if (left == null || right == null) {
    return left == right;
  }
  if (left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) {
      return false;
    }
  }
  return true;
}
