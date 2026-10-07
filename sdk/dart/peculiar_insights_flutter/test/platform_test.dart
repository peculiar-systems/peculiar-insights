import "package:flutter_test/flutter_test.dart";
import "package:peculiar_insights_flutter/peculiar_insights_flutter.dart";

void main() {
  test("the flutter package re-exports the client", () {
    expect(PlatformInfo.unknown.platform, AppPlatform.unknown);
    expect(const ConsentPolicy.ask(), isA<ConsentPolicy>());
  });
}
