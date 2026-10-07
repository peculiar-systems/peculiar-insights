import "package:grpc/grpc.dart";
import "package:grpc/service_api.dart" as api;
import "package:peculiar_insights/gen/peculiar/insights/v1/ingest.pbgrpc.dart";
import "package:peculiar_insights/src/transport/channel_stub.dart"
    if (dart.library.io) "package:peculiar_insights/src/transport/channel_native.dart"
    if (dart.library.js_interop) "package:peculiar_insights/src/transport/channel_web.dart";

const protocolVersion = "1";

abstract interface class Transport {
  Future<PublishResponse> publish(PublishRequest request);

  Future<RecordConsentResponse> recordConsent(RecordConsentRequest request);

  Future<RequestErasureResponse> requestErasure(RequestErasureRequest request);
}

final class GrpcTransport implements Transport {
  GrpcTransport({
    required api.ClientChannel channel,
    required String key,
    required Duration timeout,
  }) : _client = IngestClient(
         channel,
         options: CallOptions(
           metadata: {
             "authorization": "Bearer $key",
             "x-peculiar-protocol": protocolVersion,
           },
           timeout: timeout,
         ),
       );

  factory GrpcTransport.endpoint({
    required Uri endpoint,
    required String key,
    required Duration timeout,
  }) =>
      GrpcTransport(channel: openChannel(endpoint), key: key, timeout: timeout);

  final IngestClient _client;

  @override
  Future<PublishResponse> publish(PublishRequest request) =>
      _client.publish(request);

  @override
  Future<RecordConsentResponse> recordConsent(RecordConsentRequest request) =>
      _client.recordConsent(request);

  @override
  Future<RequestErasureResponse> requestErasure(
    RequestErasureRequest request,
  ) => _client.requestErasure(request);
}
