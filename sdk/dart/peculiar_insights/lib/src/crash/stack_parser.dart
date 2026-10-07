import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:peculiar_insights/src/crash/aot_trace.dart";
import "package:peculiar_insights/src/crash/symbolic_trace.dart";
import "package:peculiar_insights/src/model/crash.dart";

IList<Frame> parseStackTrace(
  String trace, {
  required IList<String> inAppPackages,
}) =>
    AotTrace.parse(trace)?.frames ??
    SymbolicTrace(inAppPackages: inAppPackages).parse(trace);
