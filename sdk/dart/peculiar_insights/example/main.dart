import "dart:io";

import "package:peculiar_insights/peculiar_insights.dart";

Future<void> main() async {
  final insights = await Insights.start(
    url: Uri.parse("https://insights.example.org"),
    key: "replace-with-the-ingest-key",
    consent: const ConsentPolicy.assumed(
      analytics: "service-telemetry",
      diagnostics: "service-telemetry",
    ),
    app: const AppInfo(version: "1.0.0", build: "20260101120000"),
    storage: MemoryStorage(),
  );
  insights.diagnostics.listen(stderr.writeln);

  final request = insights.subject(
    const Subject(
      device: DeviceId("api-node-1"),
      user: UserId("user-123"),
      session: SessionId("request-42"),
    ),
    Consent.none.granted(Purpose.analytics, "2026-01"),
  );
  final checkout = request.with_({"flow": "checkout"});
  await checkout.track("order_placed", {"total": 42.5, "items": 3});
  await checkout.people.set({"plan": "pro"});

  final span = checkout.span("payment");
  await checkout.attempt(() async {
    await span.end({"provider": "card"});
  });

  await insights.flush();
  await insights.close();
}
