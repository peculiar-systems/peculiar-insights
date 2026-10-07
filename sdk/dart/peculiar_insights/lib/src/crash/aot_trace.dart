import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:fixnum/fixnum.dart";
import "package:peculiar_insights/src/model/crash.dart";

enum AotSection {
  isolate("_kDartIsolateSnapshotInstructions"),
  vm("_kDartVmSnapshotInstructions");

  const AotSection(this.symbol);

  final String symbol;

  static AotSection of(String location) =>
      location.startsWith(vm.symbol) ? vm : isolate;
}

final class AotTrace {
  const AotTrace({
    required this.buildId,
    required this.isolateDsoBase,
    required this.isolateInstructions,
    required this.vmInstructions,
    required this.lines,
  });

  final String buildId;
  final Int64? isolateDsoBase;
  final Int64 isolateInstructions;
  final Int64 vmInstructions;
  final IList<String> lines;

  static final _buildId = RegExp(r"^build_id:\s*'(?<id>[0-9a-fA-F]+)'");

  static final _frame = RegExp(
    r"^#\d+\s+abs\s+(?<abs>[0-9a-fA-F]+)"
    r"(?:\s+virt\s+(?<virt>[0-9a-fA-F]+))?\s*(?<location>.*)$",
  );

  static AotTrace? parse(String trace) {
    final lines = trace.split("\n").map((line) => line.trim()).toIList();
    final buildId = lines
        .map(_buildId.firstMatch)
        .nonNulls
        .firstOrNull
        ?.namedGroup("id");
    if (buildId == null) {
      return null;
    }
    return AotTrace(
      buildId: buildId,
      isolateDsoBase: _header(lines, "isolate_dso_base"),
      isolateInstructions: _header(lines, "isolate_instructions") ?? Int64.ZERO,
      vmInstructions: _header(lines, "vm_instructions") ?? Int64.ZERO,
      lines: lines,
    );
  }

  static Int64? _header(IList<String> lines, String key) {
    final field = RegExp("(?:^|[\\s,])$key:\\s*(?<value>[0-9a-fA-F]+)");
    final value = lines
        .map(field.firstMatch)
        .nonNulls
        .firstOrNull
        ?.namedGroup("value");
    return value == null ? null : Int64.parseHex(value);
  }

  IList<Frame> get frames =>
      lines.map(_frame.firstMatch).nonNulls.map(_frameOf).toIList();

  Frame _frameOf(RegExpMatch match) {
    final location = match.namedGroup("location") ?? "";
    final section = AotSection.of(location);
    final absolute = Int64.parseHex(match.namedGroup("abs") ?? "0");
    final virtual = match.namedGroup("virt");
    return Frame(
      moduleName: "",
      function: location,
      file: "",
      line: 0,
      column: 0,
      inApp: section == AotSection.isolate,
      instructionAddress: virtual == null
          ? absolute - (isolateDsoBase ?? Int64.ZERO)
          : Int64.parseHex(virtual),
      image: BinaryImage(
        name: section.symbol,
        identifier: buildId,
        loadAddress: switch (section) {
          AotSection.isolate => isolateInstructions,
          AotSection.vm => vmInstructions,
        },
      ),
    );
  }
}
