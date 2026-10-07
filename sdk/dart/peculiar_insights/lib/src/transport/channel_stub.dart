import "package:grpc/service_api.dart";

ClientChannel openChannel(Uri endpoint) =>
    throw UnsupportedError("no gRPC channel is available on this platform");
