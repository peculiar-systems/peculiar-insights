import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:peculiar_insights/src/model/crash.dart";

final class SymbolicTrace {
  const SymbolicTrace({required this.inAppPackages});

  final IList<String> inAppPackages;

  static final _dartFrame = RegExp(
    r"^#\d+\s+(?<function>.+?)\s+\((?<location>[^)]+)\)$",
  );

  static final _v8Frame = RegExp(
    r"^at\s+(?:(?<function>.+?)\s+\((?<location>[^)]+)\)|(?<bare>\S+))$",
  );

  static final _geckoFrame = RegExp(r"^(?<function>[^@\s]*)@(?<location>\S+)$");

  static final _location = RegExp(
    r"^(?<file>.+?)(?::(?<line>\d+))?(?::(?<column>\d+))?$",
  );

  IList<Frame> parse(String trace) => trace
      .split("\n")
      .map((line) => _parseLine(line.trim()))
      .nonNulls
      .toIList();

  Frame? _parseLine(String line) {
    final match =
        _dartFrame.firstMatch(line) ??
        _v8Frame.firstMatch(line) ??
        _geckoFrame.firstMatch(line);
    if (match == null) {
      return null;
    }
    final function = match.namedGroup("function") ?? "";
    final location = _location.firstMatch(
      match.namedGroup("location") ?? _bareLocation(match),
    );
    final file = location?.namedGroup("file") ?? "";
    return Frame(
      moduleName: _moduleOf(file),
      function: function,
      file: file,
      line: int.tryParse(location?.namedGroup("line") ?? "") ?? 0,
      column: int.tryParse(location?.namedGroup("column") ?? "") ?? 0,
      inApp: _isInApp(file),
    );
  }

  String _bareLocation(RegExpMatch match) =>
      match.groupNames.contains("bare") ? match.namedGroup("bare") ?? "" : "";

  String _moduleOf(String file) {
    final uri = Uri.tryParse(file);
    if (uri == null) {
      return "";
    }
    return switch (uri.scheme) {
      "package" => uri.pathSegments.firstOrNull ?? "",
      "dart" => "dart:${uri.path}",
      _ => uri.pathSegments.isEmpty ? file : uri.pathSegments.first,
    };
  }

  bool _isInApp(String file) {
    if (file.startsWith("dart:")) {
      return false;
    }
    if (!file.startsWith("package:")) {
      return true;
    }
    return inAppPackages.contains(_moduleOf(file));
  }
}
