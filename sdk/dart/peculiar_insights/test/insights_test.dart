import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:grpc/grpc.dart";
import "package:peculiar_insights/gen/peculiar/insights/v1/ingest.pb.dart"
    as pb;
import "package:peculiar_insights/internal.dart";
import "package:peculiar_insights/peculiar_insights.dart";
import "package:test/test.dart";

const app = AppInfo(version: "1", build: "1");

const quiet = InsightsOptions(flushInterval: Duration(days: 1));

Future<(Insights, MemoryStorage, RecordingTransport)> boot({
  ConsentPolicy consent = const ConsentPolicy.ask(),
  InsightsOptions options = quiet,
}) async {
  final storage = MemoryStorage();
  final transport = RecordingTransport();
  var counter = 0;
  final insights = await Insights.start(
    url: Uri.parse("http://localhost:1"),
    key: "k",
    consent: consent,
    app: app,
    storage: storage,
    options: options,
    transport: transport,
    now: () => DateTime.utc(2026, 1, 1, 12),
    newId: () => "id-${counter++}",
  );
  return (insights, storage, transport);
}

final class ManualClock {
  ManualClock();

  var _time = DateTime.utc(2026, 1, 1, 12);

  DateTime now() => _time;

  void advance(Duration by) {
    _time = _time.add(by);
  }
}

final class ThrottledTransport implements Transport {
  ThrottledTransport();

  final recording = RecordingTransport();
  IList<GrpcError> _refusals = const IListConst([]);
  var _attempts = 0;

  int get attempts => _attempts;

  void refuse(Iterable<GrpcError> refusals) {
    _refusals = _refusals.addAll(refusals);
  }

  Future<T> _pass<T>(Future<T> Function() send) {
    _attempts += 1;
    final refusal = _refusals.firstOrNull;
    _refusals = _refusals.skip(1).toIList();
    return refusal == null ? send() : Future.error(refusal);
  }

  @override
  Future<pb.PublishResponse> publish(pb.PublishRequest request) =>
      _pass(() => recording.publish(request));

  @override
  Future<pb.RecordConsentResponse> recordConsent(
    pb.RecordConsentRequest request,
  ) => _pass(() => recording.recordConsent(request));

  @override
  Future<pb.RequestErasureResponse> requestErasure(
    pb.RequestErasureRequest request,
  ) => _pass(() => recording.requestErasure(request));
}

GrpcError rateLimited([String? pushback]) => GrpcError.custom(
  StatusCode.resourceExhausted,
  "rate limited",
  null,
  null,
  pushback == null ? const {} : {pushbackTrailer: pushback},
);

Future<(Insights, MemoryStorage, ThrottledTransport, ManualClock)>
bootThrottled() async {
  final storage = MemoryStorage();
  final transport = ThrottledTransport();
  final clock = ManualClock();
  var counter = 0;
  final insights = await Insights.start(
    url: Uri.parse("http://localhost:1"),
    key: "k",
    consent: const ConsentPolicy.assumed(analytics: "test"),
    app: app,
    storage: storage,
    options: quiet,
    transport: transport,
    now: clock.now,
    newId: () => "id-${counter++}",
  );
  return (insights, storage, transport, clock);
}

Future<void> grantAll(Insights insights) async {
  await insights.consent.grant(Purpose.analytics, policyVersion: "v1");
  await insights.consent.grant(Purpose.diagnostics, policyVersion: "v1");
}

void main() {
  test("events before a decision stay in memory", () async {
    final (insights, storage, transport) = await boot();
    await insights.tracker.track("open");
    expect(insights.buffered, 1);
    expect(storage.rows, isEmpty);
    expect(await storage.readState(StateKeys.deviceId), isNull);
    expect(transport.published, isEmpty);
    await insights.close();
  });

  test("a grant persists the device id and flushes the buffer", () async {
    final (insights, storage, transport) = await boot();
    await insights.tracker.track("open");
    await insights.consent.grant(Purpose.analytics, policyVersion: "v1");
    expect(
      await storage.readState(StateKeys.deviceId),
      insights.deviceId.value,
    );
    expect(transport.consents.length, 1);
    expect(transport.eventNames, ["open"]);
    expect(transport.published.single.consent.purposes.length, 1);
    expect(insights.buffered, 0);
    await insights.close();
  });

  test("an assumed policy grants at start with the basis as version", () async {
    final (insights, _, transport) = await boot(
      consent: const ConsentPolicy.assumed(analytics: "legitimate-interest"),
    );
    await insights.tracker.track("open");
    await insights.flush();
    expect(
      transport.consents.single.purpose.policyVersion,
      "legitimate-interest",
    );
    expect(transport.eventNames, ["open"]);
    expect(insights.consent.status.permits(Purpose.diagnostics), isFalse);
    await insights.close();
  });

  test("a withdrawal drops the queue and the device id", () async {
    final (insights, storage, transport) = await boot();
    await insights.consent.grant(Purpose.analytics, policyVersion: "v1");
    await insights.consent.withdraw(Purpose.analytics);
    expect(await storage.readState(StateKeys.deviceId), isNull);
    expect(transport.consents.length, 2);
    expect(
      transport.consents.last.purpose.state.name,
      "CONSENT_STATE_WITHDRAWN",
    );
    await insights.tracker.track("after");
    expect(insights.buffered, 0);
    expect(storage.rows, isEmpty);
    await insights.close();
  });

  test("a denial before any grant sends nothing", () async {
    final (insights, storage, transport) = await boot();
    await insights.tracker.track("open");
    await insights.consent.withdraw(Purpose.analytics);
    expect(transport.consents, isEmpty);
    expect(transport.published, isEmpty);
    expect(insights.buffered, 0);
    expect(await storage.readState(StateKeys.consent), isNotNull);
    await insights.close();
  });

  test("the privacy control signal counts as a denial", () async {
    final (insights, _, transport) = await boot(
      options: quiet.copyWith(privacyControlSignal: true),
    );
    await insights.tracker.track("open");
    expect(insights.buffered, 0);
    expect(transport.published, isEmpty);
    await insights.close();
  });

  test(
    "child trackers fold their properties into events and crashes",
    () async {
      final (insights, _, transport) = await boot();
      await grantAll(insights);
      final screen = insights.tracker.with_({"screen": "checkout", "step": 1});
      final payment = screen.with_({"step": 2});
      await payment.track("pay_tapped", {"total": 42.5});
      await payment.recordError(StateError("declined"), StackTrace.empty);
      await insights.flush();
      final event = transport.events.single;
      expect(event.properties["screen"]?.stringValue, "checkout");
      expect(event.properties["step"]?.intValue.toInt(), 2);
      expect(event.properties["total"]?.doubleValue, 42.5);
      expect(
        transport.crashes.single.customKeys["screen"]?.stringValue,
        "checkout",
      );
      expect(insights.tracker.properties, isEmpty);
      await insights.close();
    },
  );

  test("values convert from plain dart and nulls are absent", () async {
    final (insights, _, transport) = await boot();
    await grantAll(insights);
    await insights.tracker.track("shape", {
      "text": "t",
      "int": 1,
      "double": 1.5,
      "flag": true,
      "time": DateTime.utc(2026),
      "list": [1, "two"],
      "map": {"nested": true},
      "absent": null,
    });
    await insights.flush();
    final properties = transport.events.single.properties;
    expect(properties.keys, isNot(contains("absent")));
    expect(properties["list"]?.listValue.values.length, 2);
    expect(properties["map"]?.mapValue.entries["nested"]?.boolValue, isTrue);
    expect(properties["time"]?.hasTimeValue(), isTrue);
    await insights.close();
  });

  test("an unconvertible value asserts in debug", () async {
    final (insights, _, _) = await boot();
    await grantAll(insights);
    expect(
      () => insights.tracker.track("bad", {"object": Object()}),
      throwsA(isA<AssertionError>()),
    );
    await insights.close();
  });

  test("a span tracks its duration", () async {
    var tick = 0;
    final storage = MemoryStorage();
    final transport = RecordingTransport();
    final insights = await Insights.start(
      url: Uri.parse("http://localhost:1"),
      key: "k",
      consent: const ConsentPolicy.assumed(analytics: "test"),
      app: app,
      storage: storage,
      options: quiet,
      transport: transport,
      now: () => DateTime.utc(2026, 1, 1, 12, 0, 0, tick++ * 250),
    );
    final span = insights.tracker.span("checkout");
    await span.end({"items": 3});
    await span.end();
    await insights.flush();
    final event = transport.events.single;
    expect(event.name, "checkout");
    expect(event.properties["duration_ms"]?.intValue.toInt(), greaterThan(0));
    expect(event.properties["items"]?.intValue.toInt(), 3);
    await insights.close();
  });

  test("attempt records a non-fatal error and rethrows", () async {
    final (insights, _, transport) = await boot();
    await grantAll(insights);
    await expectLater(
      insights.tracker.attempt(() => throw StateError("boom")),
      throwsA(isA<StateError>()),
    );
    await insights.flush();
    expect(transport.crashes.single.fatal, isFalse);
    expect(transport.crashes.single.exceptionType, "StateError");
    await insights.close();
  });

  test("crash reports follow the diagnostics purpose", () async {
    final (insights, storage, transport) = await boot();
    await insights.consent.grant(Purpose.diagnostics, policyVersion: "v1");
    await insights.tracker.recordError(
      StateError("bad"),
      StackTrace.fromString("#0      main (package:app/main.dart:1:1)"),
      fatal: true,
    );
    final crash = transport.crashes.single;
    expect(crash.fatal, isTrue);
    expect(crash.frames.single.function, "main");
    await insights.tracker.track("open");
    expect(insights.buffered, 1);
    expect(storage.rows, isEmpty);
    await insights.close();
  });

  test("diagnostics stream reports dropped items", () async {
    final (insights, _, _) = await boot();
    final seen = <Diagnostic>[];
    final subscription = insights.diagnostics.listen(seen.add);
    await insights.consent.withdraw(Purpose.analytics);
    await insights.tracker.track("open");
    await Future<void>.delayed(Duration.zero);
    expect(seen.whereType<DroppedDiagnostic>().length, 1);
    await subscription.cancel();
    await insights.close();
  });

  test("a subject tracker carries its own consent", () async {
    final (insights, _, transport) = await boot();
    final granted = Consent.none.granted(Purpose.analytics, "v2");
    final request = insights.subject(
      const Subject(
        device: DeviceId("api"),
        user: UserId("alice"),
        session: SessionId("req-1"),
      ),
      granted,
    );
    await request.track("order_placed");
    await request.people.set({"plan": "pro"});
    await insights.flush();
    expect(
      transport.published.map((r) => r.consent.purposes.single.policyVersion),
      everyElement("v2"),
    );
    expect(transport.events.single.subject.userId, "alice");
    expect(transport.items.length, 2);
    final denied = insights.subject(
      const Subject(
        device: DeviceId("api"),
        user: null,
        session: SessionId("req-2"),
      ),
      Consent.none,
    );
    await denied.track("ignored");
    await insights.flush();
    expect(transport.eventNames, ["order_placed"]);
    await insights.close();
  });

  test("erasure clears the queue and mints a new device id", () async {
    final (insights, storage, transport) = await boot();
    await insights.consent.grant(Purpose.analytics, policyVersion: "v1");
    await insights.tracker.identify(const UserId("alice"));
    final before = insights.deviceId;
    await insights.erase();
    expect(transport.erasures.single.deviceId, before.value);
    expect(transport.erasures.single.userId, "alice");
    expect(insights.deviceId, isNot(before));
    expect(insights.userId, isNull);
    expect(storage.rows, isEmpty);
    await insights.close();
  });

  test("profile updates need an identified user", () async {
    final (insights, _, transport) = await boot();
    await grantAll(insights);
    final seen = <Diagnostic>[];
    final subscription = insights.diagnostics.listen(seen.add);
    await insights.tracker.people.set({"plan": "pro"});
    await Future<void>.delayed(Duration.zero);
    expect(seen.whereType<DroppedDiagnostic>().length, 1);
    await insights.tracker.identify(const UserId("bob"));
    await insights.tracker.people.setOnce({"signup": DateTime.utc(2026)});
    await insights.tracker.people.unset(["plan"]);
    await insights.flush();
    expect(transport.items.where((i) => i.hasProfileUpdate()).length, 2);
    await subscription.cancel();
    await insights.close();
  });

  test("a rate-limited batch is kept and delivered once", () async {
    final (insights, storage, transport, clock) = await bootThrottled();
    final seen = <Diagnostic>[];
    final subscription = insights.diagnostics.listen(seen.add);
    transport.refuse([rateLimited("3000"), rateLimited("3000")]);
    await insights.tracker.track("open");
    await insights.tracker.track("close");
    await insights.flush();
    expect(transport.recording.published, isEmpty);
    expect(storage.rows.length, 2);
    clock.advance(const Duration(seconds: 3));
    await insights.flush();
    expect(transport.recording.published, isEmpty);
    expect(storage.rows.length, 2);
    clock.advance(const Duration(seconds: 3));
    await insights.flush();
    await Future<void>.delayed(Duration.zero);
    expect(transport.recording.eventNames, ["open", "close"]);
    expect(transport.recording.published.length, 1);
    expect(transport.recording.consents.length, 1);
    expect(storage.rows, isEmpty);
    expect(seen, const [
      Diagnostic.transportFailed(
        code: StatusCode.resourceExhausted,
        message: "rate limited",
        willRetry: true,
      ),
      Diagnostic.transportFailed(
        code: StatusCode.resourceExhausted,
        message: "rate limited",
        willRetry: true,
      ),
    ]);
    await subscription.cancel();
    await insights.close();
  });

  test("a rate-limited consent record and erasure stay queued", () async {
    final (insights, storage, transport, clock) = await bootThrottled();
    transport.refuse([rateLimited("1000")]);
    await insights.consent.grant(Purpose.diagnostics, policyVersion: "v1");
    expect(transport.recording.consents.length, 1);
    expect(storage.rows.single.kind, QueueKind.consent);
    clock.advance(const Duration(seconds: 1));
    transport.refuse([rateLimited("1000")]);
    await insights.erase();
    expect(transport.recording.erasures, isEmpty);
    expect(storage.rows.single.kind, QueueKind.erasure);
    clock.advance(const Duration(seconds: 1));
    await insights.flush();
    expect(transport.recording.erasures.length, 1);
    expect(storage.rows, isEmpty);
    await insights.close();
  });

  test("the pushback the server asks for is honoured", () async {
    final (insights, storage, transport, clock) = await bootThrottled();
    transport.refuse([rateLimited("3000")]);
    await insights.tracker.track("open");
    await insights.flush();
    final refused = transport.attempts;
    clock.advance(const Duration(milliseconds: 2999));
    await insights.flush();
    expect(transport.attempts, refused);
    expect(storage.rows.length, 1);
    clock.advance(const Duration(milliseconds: 1));
    await insights.flush();
    expect(transport.attempts, refused + 1);
    expect(transport.recording.eventNames, ["open"]);
    expect(storage.rows, isEmpty);
    await insights.close();
  });

  test("a pushback past five minutes waits five minutes", () async {
    final (insights, _, transport, clock) = await bootThrottled();
    transport.refuse([rateLimited("3600000")]);
    await insights.tracker.track("open");
    await insights.flush();
    clock.advance(const Duration(minutes: 5) - const Duration(milliseconds: 1));
    await insights.flush();
    expect(transport.recording.published, isEmpty);
    clock.advance(const Duration(milliseconds: 1));
    await insights.flush();
    expect(transport.recording.eventNames, ["open"]);
    await insights.close();
  });

  test("a malformed pushback falls back to the backoff", () async {
    final (insights, storage, transport, clock) = await bootThrottled();
    transport.refuse([rateLimited("soon"), rateLimited()]);
    await insights.tracker.track("open");
    await insights.flush();
    final refused = transport.attempts;
    clock.advance(backoffDelay(0) - const Duration(milliseconds: 1));
    await insights.flush();
    expect(transport.attempts, refused);
    clock.advance(const Duration(milliseconds: 1));
    await insights.flush();
    expect(transport.attempts, refused + 1);
    expect(storage.rows.length, 1);
    clock.advance(backoffDelay(1) - const Duration(milliseconds: 1));
    await insights.flush();
    expect(transport.attempts, refused + 1);
    clock.advance(const Duration(milliseconds: 1));
    await insights.flush();
    expect(transport.attempts, refused + 2);
    expect(transport.recording.eventNames, ["open"]);
    expect(storage.rows, isEmpty);
    await insights.close();
  });
}
