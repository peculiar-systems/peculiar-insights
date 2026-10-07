import "dart:math";

import "package:grpc/grpc.dart";

const baseDelay = Duration(seconds: 1);
const maxDelay = Duration(minutes: 5);
const maxPushback = Duration(minutes: 5);
const pushbackTrailer = "x-peculiar-retry-after-ms";

final _digits = RegExp(r"^[0-9]+$");

Duration backoffDelay(int attempt) {
  final factor = pow(2, attempt.clamp(0, 30)).toInt();
  final scaled = baseDelay * factor;
  return scaled > maxDelay ? maxDelay : scaled;
}

Duration? retryPushback(Map<String, String>? trailers) {
  final raw = trailers?.entries
      .where((entry) => entry.key.toLowerCase() == pushbackTrailer)
      .map((entry) => entry.value.trim())
      .firstOrNull;
  if (raw == null || !_digits.hasMatch(raw)) {
    return null;
  }
  final asked = int.tryParse(raw) ?? maxPushback.inMilliseconds;
  return Duration(milliseconds: min(asked, maxPushback.inMilliseconds));
}

typedef Pace = ({int attempt, int throttled, DateTime? heldUntil});

const Pace steadyPace = (attempt: 0, throttled: 0, heldUntil: null);

extension PaceSteps on Pace {
  bool holds(DateTime Function() now) => switch (heldUntil) {
    final until? => now().isBefore(until),
    null => false,
  };

  Duration get throttleFallback => backoffDelay(throttled);

  Pace failed() =>
      (attempt: attempt + 1, throttled: throttled, heldUntil: heldUntil);

  Pace throttledUntil(DateTime until) =>
      (attempt: attempt, throttled: throttled + 1, heldUntil: until);

  Pace released() => (attempt: attempt, throttled: throttled, heldUntil: null);
}

enum FailureClass { retry, poison, surface }

FailureClass classify(int code) => switch (code) {
  StatusCode.unavailable ||
  StatusCode.unknown ||
  StatusCode.deadlineExceeded ||
  StatusCode.resourceExhausted => FailureClass.retry,
  StatusCode.invalidArgument => FailureClass.poison,
  _ => FailureClass.surface,
};
