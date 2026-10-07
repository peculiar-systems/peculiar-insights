{
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.fileset) toSource unions;

  protoSource = toSource {
    root = ../proto;
    fileset = ../proto;
  };

  protoFiles = lib.concatStringsSep " " (
    map (name: "peculiar/insights/v1/${name}.proto") [
      "options"
      "common"
      "ingest"
    ]
  );

  proto-dart =
    pkgs.runCommand "peculiar-insights-proto-dart"
      {
        nativeBuildInputs = [
          pkgs.protobuf
          pkgs.protoc-gen-dart
        ];
      }
      ''
        mkdir -p "$out"
        protoc \
          --dart_out=grpc:"$out" \
          -I ${protoSource} \
          -I ${pkgs.protobuf}/include \
          ${protoFiles}
      '';

  package = ../sdk/dart/peculiar_insights;

  source = toSource {
    root = package;
    fileset = unions [
      (package + "/pubspec.yaml")
      (package + "/analysis_options.yaml")
      (package + "/LICENSE")
      (package + "/lib")
      (package + "/test")
      (package + "/example")
    ];
  };

  withGenerated = pkgs.runCommandLocal "source" { } ''
    cp -r ${source} "$out"
    chmod -R u+w "$out"
    mkdir -p "$out/lib/gen"
    cp -r ${proto-dart}/. "$out/lib/gen/"
  '';

  sqlite3Builder =
    { version, src, ... }:
    pkgs.stdenv.mkDerivation (finalAttrs: {
      pname = "sqlite3";
      inherit version src;
      inherit (src) passthru;
      setupHook = pkgs.writeScript "${finalAttrs.pname}-setup-hook" ''
        sqliteFixupHook() {
          runtimeDependencies+=('${lib.getLib pkgs.sqlite}')
        }
        preFixupHooks+=(sqliteFixupHook)
      '';
      postPatch = ''
        substituteInPlace lib/src/hook/compile/description.dart \
          --replace-fail "return fromGitHub(LibraryType.sqlite3);" "return LookupSystem('sqlite3');"
        substituteInPlace lib/src/hook/compile/description.dart \
          --replace-fail "return fromGitHub(LibraryType.sqlcipher);" "return LookupSystem('sqlite3');"
      '';
      installPhase = ''
        runHook preInstall
        cp --recursive . "$out"
        runHook postInstall
      '';
    });

  checked = pkgs.buildDartApplication {
    pname = "peculiar-insights-dart-check";
    version = "0.1.0";
    src = withGenerated;
    pubspecLock = lib.importJSON (package + "/pubspec.lock.json");
    customSourceBuilders.sqlite3 = sqlite3Builder;
    dartOutputType = "kernel";
    buildPhase = ''
      runHook preBuild
      export HOME="$TMPDIR"
      dart analyze --fatal-infos
      packageRun test
      runHook postBuild
    '';
    installPhase = ''
      runHook preInstall
      mkdir -p "$out" "$pubcache"
      runHook postInstall
    '';
    dontFixup = true;
  };

  flutterPackage = ../sdk/dart/peculiar_insights_flutter;

  flutterSource = toSource {
    root = flutterPackage;
    fileset = unions [
      (flutterPackage + "/pubspec.yaml")
      (flutterPackage + "/analysis_options.yaml")
      (flutterPackage + "/LICENSE")
      (flutterPackage + "/lib")
      (flutterPackage + "/test")
      (flutterPackage + "/android/build.gradle.kts")
      (flutterPackage + "/android/settings.gradle.kts")
      (flutterPackage + "/android/src")
      (flutterPackage + "/ios")
      (flutterPackage + "/macos")
      (flutterPackage + "/src")
    ];
  };

  workspace = pkgs.runCommandLocal "source" { } ''
    mkdir -p "$out"
    cp -r ${withGenerated} "$out/peculiar_insights"
    cp -r ${flutterSource} "$out/peculiar_insights_flutter"
    chmod -R u+w "$out"
  '';

  flutterChecked = pkgs.flutter.buildFlutterApplication {
    pname = "peculiar-insights-flutter-check";
    version = "0.1.0";
    src = workspace;
    sourceRoot = "source/peculiar_insights_flutter";
    pubspecLock = lib.importJSON (flutterPackage + "/pubspec.lock.json");
    customSourceBuilders.sqlite3 = sqlite3Builder;
    buildPhase = ''
      runHook preBuild
      flutter analyze --fatal-infos
      flutter test
      runHook postBuild
    '';
    installPhase = ''
      runHook preInstall
      mkdir -p "$out" "$debug"
      runHook postInstall
    '';
    dontFixup = true;
  };

in
{
  flake.packages = { inherit proto-dart; };

  flake.output.checks = {
    dart-check = checked;
    flutter-check = flutterChecked;
  };

  tasks.dart-codegen = {
    description = "Materialise the generated Dart protobuf code into the tree for editors";
    body = ''
      set -euo pipefail
      cd "$(${pkgs.git}/bin/git rev-parse --show-toplevel)"
      rm -rf sdk/dart/peculiar_insights/lib/gen
      mkdir -p sdk/dart/peculiar_insights/lib/gen
      cp -r ${proto-dart}/. sdk/dart/peculiar_insights/lib/gen/
      chmod -R u+w sdk/dart/peculiar_insights/lib/gen
    '';
  };

  tasks.dart-lock = {
    description = "Refresh pubspec.lock.json for the Dart packages from their pubspec.lock";
    body = ''
      set -euo pipefail
      cd "$(${pkgs.git}/bin/git rev-parse --show-toplevel)"
      for package in sdk/dart/peculiar_insights sdk/dart/peculiar_insights_flutter; do
        ${pkgs.yq}/bin/yq . "$package/pubspec.lock" > "$package/pubspec.lock.json"
      done
    '';
  };
}
