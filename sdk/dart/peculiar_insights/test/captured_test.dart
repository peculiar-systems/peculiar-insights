import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:fixnum/fixnum.dart";
import "package:peculiar_insights/captured.dart";
import "package:peculiar_insights/peculiar_insights.dart";
import "package:test/test.dart";

Future<(Insights, RecordingTransport)> boot() async {
  final transport = RecordingTransport();
  final insights = await Insights.start(
    url: Uri.parse("http://localhost:1"),
    key: "k",
    consent: const ConsentPolicy.ask(),
    app: const AppInfo(version: "2.0.0", build: "20"),
    storage: MemoryStorage(),
    options: const InsightsOptions(flushInterval: Duration(days: 1)),
    transport: transport,
    now: () => DateTime.utc(2026, 1, 1, 12),
  );
  return (insights, transport);
}

final captured = CapturedCrash(
  id: "4f0c3c4e-7b1a-4d8e-9a55-0d2f3b8c1e77",
  time: DateTime.utc(2025, 12, 31, 23),
  exceptionType: "SIGSEGV",
  message: "fault address 0x0",
  thread: "main",
  frames: IList([
    Frame(
      moduleName: "libshop.so",
      function: "crash_now",
      file: "",
      line: 0,
      column: 0,
      inApp: true,
      instructionAddress: Int64.parseHex("7b2aa2b1a7"),
      image: BinaryImage(
        name: "libshop.so",
        identifier: "a1b2c3",
        loadAddress: Int64.parseHex("7b2a8c4000"),
      ),
    ),
  ]),
  app: const AppInfo(version: "1.0.0", build: "10"),
);

void main() {
  test("a captured crash is sent as a fatal report of its own build", () async {
    final (insights, transport) = await boot();
    await insights.consent.grant(Purpose.diagnostics, policyVersion: "v1");
    await insights.recordCaptured(captured);
    await insights.flush();
    final crash = transport.crashes.single;
    expect(crash.id, captured.id);
    expect(crash.fatal, isTrue);
    expect(crash.exceptionType, "SIGSEGV");
    expect(crash.context.appVersion, "1.0.0");
    expect(crash.context.appBuild, "10");
    expect(crash.time.toDateTime(), captured.time);
    expect(
      crash.frames.single.instructionAddress,
      Int64.parseHex("7b2aa2b1a7"),
    );
    expect(crash.frames.single.image.identifier, "a1b2c3");
    await insights.close();
  });

  test("consent changes and erasure are announced", () async {
    final (insights, _) = await boot();
    final changes = insights.changes.toList();
    await insights.consent.grant(Purpose.diagnostics, policyVersion: "v1");
    await insights.consent.withdraw(Purpose.diagnostics);
    await insights.erase();
    await insights.close();
    final seen = await changes;
    expect(seen.length, 3);
    expect(
      seen[0],
      isA<ConsentedChange>().having(
        (c) => c.consent.permits(Purpose.diagnostics),
        "diagnostics",
        isTrue,
      ),
    );
    expect(
      seen[1],
      isA<ConsentedChange>().having(
        (c) => c.consent.permits(Purpose.diagnostics),
        "diagnostics",
        isFalse,
      ),
    );
    expect(seen[2], const DeviceChange.erased());
  });
}
