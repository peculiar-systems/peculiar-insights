import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:peculiar_insights/internal.dart";
import "package:peculiar_insights/peculiar_insights.dart";
import "package:test/test.dart";

Outgoing eventNamed(String name) => Outgoing.event(
  id: name,
  time: DateTime.utc(2026),
  subject: const Subject(
    device: DeviceId("d"),
    user: null,
    session: SessionId("s"),
  ),
  context: const AppContext(
    sdkName: "test",
    sdkVersion: "0",
    appVersion: "1",
    appBuild: "1",
    platform: PlatformInfo.unknown,
  ),
  name: name,
  properties: const IMapConst({}),
);

void main() {
  test("the buffer keeps the newest items once the limit is reached", () {
    final buffer = ["a", "b", "c"]
        .map(eventNamed)
        .fold(const PendingBuffer(limit: 2), (b, item) => b.push(item));
    expect(buffer.of(Purpose.analytics).map((i) => i.id), ["b", "c"]);
    expect(buffer.length, 2);
  });

  test("dropping a purpose leaves the other untouched", () {
    final buffer = const PendingBuffer(
      limit: 10,
    ).push(eventNamed("a")).drop(Purpose.diagnostics);
    expect(buffer.of(Purpose.analytics).length, 1);
    expect(buffer.drop(Purpose.analytics).length, 0);
  });
}
