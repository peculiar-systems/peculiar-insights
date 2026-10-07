import "dart:io";

import "package:fixnum/fixnum.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:peculiar_insights_flutter/peculiar_insights_flutter.dart";
import "package:peculiar_insights_flutter/src/native_crash/native_crashes.dart";

const signalReport = """
{"id":"0b6a4c1e-2f3d-4a5b-8c7d-9e0f1a2b3c4d","timeMillis":1767222000000,"exceptionType":"SIGSEGV","message":"fault address 0x0","thread":"main","appVersion":"1.0.0","appBuild":"10","frames":[{"module":"libshop.so","function":"crash_now","file":"","line":0,"inApp":true,"address":"7b2aa2b1a7","image":{"name":"libshop.so","identifier":"9f86d081884c7d659a2feaa0c55ad015","loadAddress":"7b2a8c4000"}},{"module":"libc.so","function":"","file":"","line":0,"inApp":false,"address":"7b30001000","image":{"name":"libc.so","identifier":"1e2d","loadAddress":"7b30000000"}}]}
""";

const jvmReport = """
{"id":"5c1d2e3f-4a5b-4c6d-8e7f-0a1b2c3d4e5f","timeMillis":1767222000000,"exceptionType":"java.lang.IllegalStateException","message":"bad","thread":"main","appVersion":"1.0.0","appBuild":"10","frames":[{"module":"shop.Checkout","function":"pay","file":"Checkout.kt","line":42,"inApp":true}]}
""";

final class Harness {
  Harness(this.directory)
    : crashes = NativeCrashes(
        directory: directory,
        app: const AppInfo(version: "2.0.0", build: "20"),
      );

  final Directory directory;
  final NativeCrashes crashes;
  final recording = RecordingTransport();
  final configured = <Map<Object?, Object?>>[];

  Future<(Insights, Stream<DeviceChange>)> start(ConsentPolicy consent) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel(NativeCrashes.channelName),
          (call) async {
            configured.add(call.arguments as Map<Object?, Object?>);
            return null;
          },
        );
    final insights = await Insights.start(
      url: Uri.parse("http://localhost:1"),
      key: "k",
      consent: consent,
      app: const AppInfo(version: "2.0.0", build: "20"),
      storage: MemoryStorage(),
      options: const InsightsOptions(flushInterval: Duration(days: 1)),
      transport: recording,
    );
    return (insights, await crashes.attach(insights));
  }

  File write(String name, String content) =>
      File("${directory.path}/$name")..writeAsStringSync(content);

  bool get capturing => configured.last["capture"] == true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp("native_crashes");
  });

  tearDown(() async {
    await directory.delete(recursive: true);
  });

  test(
    "a waiting native report is sent at start and its file removed",
    () async {
      final harness = Harness(directory);
      final signal = harness.write("signal.json", signalReport);
      final jvm = harness.write("jvm.json", jvmReport);
      final (insights, _) = await harness.start(
        const ConsentPolicy.assumed(diagnostics: "test"),
      );
      await insights.flush();
      final crashes = harness.recording.crashes;
      expect(crashes.length, 2);
      final native = crashes.firstWhere((c) => c.exceptionType == "SIGSEGV");
      expect(native.fatal, isTrue);
      expect(native.id, "0b6a4c1e-2f3d-4a5b-8c7d-9e0f1a2b3c4d");
      expect(native.context.appVersion, "1.0.0");
      expect(native.context.appBuild, "10");
      expect(native.thread, "main");
      final top = native.frames.first;
      expect(top.instructionAddress, Int64.parseHex("7b2aa2b1a7"));
      expect(top.image.name, "libshop.so");
      expect(top.image.identifier, "9f86d081884c7d659a2feaa0c55ad015");
      expect(top.image.loadAddress, Int64.parseHex("7b2a8c4000"));
      final java = crashes.firstWhere((c) => c.exceptionType != "SIGSEGV");
      expect(java.frames.single.file, "Checkout.kt");
      expect(java.frames.single.line, 42);
      expect(java.frames.single.hasInstructionAddress(), isFalse);
      expect(signal.existsSync(), isFalse);
      expect(jvm.existsSync(), isFalse);
      expect(harness.capturing, isTrue);
      expect(harness.configured.last["directory"], directory.path);
      await insights.close();
    },
  );

  test("without diagnostics nothing is sent and nothing is captured", () async {
    final harness = Harness(directory);
    final signal = harness.write("signal.json", signalReport);
    final (insights, _) = await harness.start(
      const ConsentPolicy.assumed(analytics: "test"),
    );
    await insights.flush();
    expect(harness.recording.crashes, isEmpty);
    expect(signal.existsSync(), isFalse);
    expect(harness.capturing, isFalse);
    await insights.close();
  });

  test("withdrawing diagnostics removes waiting reports", () async {
    final harness = Harness(directory);
    final (insights, handled) = await harness.start(const ConsentPolicy.ask());
    expect(harness.capturing, isFalse);
    final granted = handled.first;
    await insights.consent.grant(Purpose.diagnostics, policyVersion: "v1");
    expect(await granted, isA<ConsentedChange>());
    expect(harness.capturing, isTrue);
    final signal = harness.write("signal.json", signalReport);
    final withdrawn = handled.first;
    await insights.consent.withdraw(Purpose.diagnostics);
    expect(await withdrawn, isA<ConsentedChange>());
    expect(signal.existsSync(), isFalse);
    expect(harness.capturing, isFalse);
    expect(harness.recording.crashes, isEmpty);
    await insights.close();
  });

  test("an unreadable report is discarded without sending", () async {
    final harness = Harness(directory);
    final broken = harness.write("broken.json", '{"id":');
    final partial = harness.write("partial.json.tmp", signalReport);
    final (insights, _) = await harness.start(
      const ConsentPolicy.assumed(diagnostics: "test"),
    );
    await insights.flush();
    expect(harness.recording.crashes, isEmpty);
    expect(broken.existsSync(), isFalse);
    expect(partial.existsSync(), isTrue);
    await insights.close();
  });

  test("erasing removes waiting reports", () async {
    final harness = Harness(directory);
    final (insights, handled) = await harness.start(
      const ConsentPolicy.assumed(diagnostics: "test"),
    );
    final signal = harness.write("signal.json", signalReport);
    final erased = handled.first;
    await insights.erase();
    expect(await erased, isA<ErasedChange>());
    expect(signal.existsSync(), isFalse);
    expect(harness.recording.crashes, isEmpty);
    await insights.close();
  });
}
