import "package:grpc/grpc.dart";
import "package:peculiar_insights/internal.dart";
import "package:test/test.dart";

void main() {
  test("delays double and cap", () {
    expect(backoffDelay(0), const Duration(seconds: 1));
    expect(backoffDelay(3), const Duration(seconds: 8));
    expect(backoffDelay(40), maxDelay);
  });

  test("transport failures retry, bad requests poison, the rest surface", () {
    expect(classify(StatusCode.unavailable), FailureClass.retry);
    expect(classify(StatusCode.unknown), FailureClass.retry);
    expect(classify(StatusCode.deadlineExceeded), FailureClass.retry);
    expect(classify(StatusCode.resourceExhausted), FailureClass.retry);
    expect(classify(StatusCode.invalidArgument), FailureClass.poison);
    expect(classify(StatusCode.unauthenticated), FailureClass.surface);
  });

  test("a pushback is the milliseconds the server asks for", () {
    expect(
      retryPushback(const {pushbackTrailer: "3000"}),
      const Duration(seconds: 3),
    );
    expect(retryPushback(const {pushbackTrailer: "0"}), Duration.zero);
    expect(
      retryPushback(const {"X-Peculiar-Retry-After-Ms": " 250 "}),
      const Duration(milliseconds: 250),
    );
  });

  test("a pushback caps at five minutes", () {
    expect(retryPushback(const {pushbackTrailer: "300001"}), maxPushback);
    expect(
      retryPushback(const {pushbackTrailer: "99999999999999999999999999"}),
      maxPushback,
    );
    expect(maxPushback, const Duration(minutes: 5));
  });

  test("an absent or malformed pushback is no pushback", () {
    expect(retryPushback(null), isNull);
    expect(retryPushback(const {}), isNull);
    expect(retryPushback(const {"retry-after": "3"}), isNull);
    for (final malformed in ["", "soon", "-1", "+5", "1.5", "0x10", "1e3"]) {
      expect(retryPushback({pushbackTrailer: malformed}), isNull);
    }
  });

  test("a throttled pace holds until its time and keeps the attempt", () {
    final start = DateTime.utc(2026, 1, 1, 12);
    final until = start.add(const Duration(seconds: 3));
    final held = steadyPace.failed().throttledUntil(until);
    expect(held.attempt, 1);
    expect(held.throttled, 1);
    expect(held.throttleFallback, const Duration(seconds: 2));
    expect(held.holds(() => start), isTrue);
    expect(
      held.holds(() => until.subtract(const Duration(milliseconds: 1))),
      isTrue,
    );
    expect(held.holds(() => until), isFalse);
    expect(held.released().holds(() => start), isFalse);
    expect(steadyPace.holds(() => start), isFalse);
  });
}
