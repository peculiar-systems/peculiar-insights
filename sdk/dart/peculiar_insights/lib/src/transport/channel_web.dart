import "package:grpc/grpc_web.dart";
import "package:grpc/service_api.dart";

ClientChannel openChannel(Uri endpoint) => GrpcWebClientChannel.xhr(endpoint);
