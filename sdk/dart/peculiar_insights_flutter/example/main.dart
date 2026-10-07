import "dart:async";

import "package:flutter/material.dart";
import "package:peculiar_insights_flutter/peculiar_insights_flutter.dart";

Future<void> main() async {
  final insights = await FlutterInsights.start(
    url: Uri.parse("https://insights.example.org"),
    key: "replace-with-the-ingest-key",
    consent: const ConsentPolicy.ask(),
    inAppPackages: const ["shop"],
    trackAppLifecycle: true,
  );
  runApp(ShopApp(insights: insights));
}

final class ShopApp extends StatelessWidget {
  const ShopApp({required this.insights, super.key});

  final Insights insights;

  @override
  Widget build(BuildContext context) => MaterialApp(
    navigatorObservers: [InsightsNavigatorObserver(insights)],
    home: ConsentGate(insights: insights),
  );
}

final class ConsentGate extends StatelessWidget {
  const ConsentGate({required this.insights, super.key});

  final Insights insights;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Help us improve the app?"),
          FilledButton(
            onPressed: () => unawaited(_accept()),
            child: const Text("Yes, share usage and crash data"),
          ),
          TextButton(
            onPressed: () => unawaited(_acceptCrashesOnly()),
            child: const Text("Only crash reports"),
          ),
          FilledButton.tonal(
            onPressed: () => unawaited(_checkout()),
            child: const Text("Open checkout"),
          ),
        ],
      ),
    ),
  );

  Future<void> _accept() async {
    await insights.consent.grant(Purpose.analytics, policyVersion: "2026-01");
    await insights.consent.grant(Purpose.diagnostics, policyVersion: "2026-01");
  }

  Future<void> _acceptCrashesOnly() =>
      insights.consent.grant(Purpose.diagnostics, policyVersion: "2026-01");

  Future<void> _checkout() async {
    final checkout = insights.tracker.with_({"screen": "checkout"});
    await checkout.identify(const UserId("user-123"));
    final span = checkout.span("checkout_completed");
    await checkout.attempt(() async {
      await checkout.track("checkout_opened", {"items": 3, "total": 42.5});
    });
    await span.end();
  }
}
