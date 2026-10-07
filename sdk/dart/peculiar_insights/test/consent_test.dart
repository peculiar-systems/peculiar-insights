import "package:peculiar_insights/peculiar_insights.dart";
import "package:test/test.dart";

void main() {
  test("nothing is permitted before a decision", () {
    expect(Consent.none.permits(Purpose.analytics), isFalse);
    expect(Consent.none.permits(Purpose.diagnostics), isFalse);
    expect(Consent.none.anyDecided, isFalse);
  });

  test("a grant permits only its purpose", () {
    final consent = Consent.none.granted(Purpose.analytics, "v1");
    expect(consent.permits(Purpose.analytics), isTrue);
    expect(consent.permits(Purpose.diagnostics), isFalse);
    expect(consent.anyGranted, isTrue);
  });

  test("a withdrawal keeps the policy version it revokes", () {
    final consent = Consent.none
        .granted(Purpose.analytics, "v3")
        .withdrawn(Purpose.analytics);
    expect(consent.permits(Purpose.analytics), isFalse);
    expect(consent.statusOf(Purpose.analytics).policyVersion, "v3");
    expect(consent.anyGranted, isFalse);
  });

  test("the snapshot survives a proto round trip", () {
    final consent = Consent.none
        .granted(Purpose.analytics, "v1")
        .withdrawn(Purpose.diagnostics);
    expect(Consent.fromProto(consent.toProto()), consent);
  });

  test("undecided purposes are absent from the snapshot", () {
    final snapshot = Consent.none.granted(Purpose.diagnostics, "v1").toProto();
    expect(snapshot.purposes.length, 1);
  });
}
