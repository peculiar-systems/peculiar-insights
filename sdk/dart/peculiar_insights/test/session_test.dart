import "package:peculiar_insights/internal.dart";
import "package:test/test.dart";

void main() {
  const timeout = Duration(minutes: 30);
  final start = DateTime.utc(2026, 1, 1, 12);
  final session = Session(id: "first", lastActivity: start);

  test("activity inside the timeout keeps the session", () {
    final touched = session.touched(
      now: start.add(const Duration(minutes: 29)),
      timeout: timeout,
      newId: () => "second",
    );
    expect(touched.id, "first");
    expect(touched.lastActivity, start.add(const Duration(minutes: 29)));
  });

  test("silence past the timeout starts a new session", () {
    final touched = session.touched(
      now: start.add(const Duration(minutes: 31)),
      timeout: timeout,
      newId: () => "second",
    );
    expect(touched.id, "second");
  });
}
