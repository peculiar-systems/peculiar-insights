import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:peculiar_insights/gen/peculiar/insights/v1/ingest.pb.dart";
import "package:peculiar_insights/src/transport/transport.dart";

final class RecordingTransport implements Transport {
  RecordingTransport();

  IList<PublishRequest> _published = const IListConst([]);
  IList<RecordConsentRequest> _consents = const IListConst([]);
  IList<RequestErasureRequest> _erasures = const IListConst([]);

  IList<PublishRequest> get published => _published;

  IList<RecordConsentRequest> get consents => _consents;

  IList<RequestErasureRequest> get erasures => _erasures;

  IList<Item> get items =>
      _published.expand((request) => request.items).toIList();

  IList<Event> get events => items
      .where((item) => item.hasEvent())
      .map((item) => item.event)
      .toIList();

  IList<CrashReport> get crashes => items
      .where((item) => item.hasCrashReport())
      .map((item) => item.crashReport)
      .toIList();

  IList<String> get eventNames => events.map((event) => event.name).toIList();

  @override
  Future<PublishResponse> publish(PublishRequest request) async {
    _published = _published.add(request);
    return PublishResponse(
      outcomes: request.items.map(
        (item) =>
            ItemOutcome(id: _idOf(item), outcome: Outcome.OUTCOME_ACCEPTED),
      ),
    );
  }

  @override
  Future<RecordConsentResponse> recordConsent(
    RecordConsentRequest request,
  ) async {
    _consents = _consents.add(request);
    return RecordConsentResponse(outcome: Outcome.OUTCOME_ACCEPTED);
  }

  @override
  Future<RequestErasureResponse> requestErasure(
    RequestErasureRequest request,
  ) async {
    _erasures = _erasures.add(request);
    return RequestErasureResponse(outcome: Outcome.OUTCOME_ACCEPTED);
  }

  static String _idOf(Item item) => switch (item.whichKind()) {
    Item_Kind.event => item.event.id,
    Item_Kind.identify => item.identify.id,
    Item_Kind.profileUpdate => item.profileUpdate.id,
    Item_Kind.crashReport => item.crashReport.id,
    Item_Kind.notSet => "",
  };
}
