import "package:grpc/grpc.dart";

ClientChannel openChannel(Uri endpoint) {
  final secure = endpoint.scheme == "https";
  return ClientChannel(
    endpoint.host,
    port: endpoint.hasPort ? endpoint.port : (secure ? 443 : 80),
    options: ChannelOptions(
      credentials: secure
          ? const ChannelCredentials.secure()
          : const ChannelCredentials.insecure(),
    ),
  );
}
