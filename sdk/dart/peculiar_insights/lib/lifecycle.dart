import "package:peculiar_insights/src/client/insights.dart";

final class AppLifecycle {
  const AppLifecycle(this._insights);

  final Insights _insights;

  void paused() => _insights.paused();

  void resumed() => _insights.resumed();
}
