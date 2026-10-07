{
  config,
  lib,
  pkgs,
  contract-main,
  ...
}:
let
  hp = pkgs.haskellPackages;
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
      "manage"
      "symbols"
      "symbolicator"
    ]
  );

  proto-hs =
    pkgs.runCommand "peculiar-insights-proto-hs"
      {
        nativeBuildInputs = [
          pkgs.protobuf
          hp.proto-lens-protoc
        ];
      }
      ''
        mkdir -p "$out"
        protoc \
          --plugin=protoc-gen-haskell=${hp.proto-lens-protoc}/bin/proto-lens-protoc \
          --haskell_out="$out" \
          -I ${protoSource} \
          -I ${pkgs.protobuf}/include \
          ${protoFiles}
      '';

  proto-descriptor =
    pkgs.runCommand "peculiar-insights-descriptor" { nativeBuildInputs = [ pkgs.protobuf ]; }
      ''
        mkdir -p "$out"
        protoc \
          --descriptor_set_out="$out/insights.binpb" \
          --include_imports \
          -I ${protoSource} \
          -I ${pkgs.protobuf}/include \
          ${protoFiles}
      '';

  bufSource = toSource {
    root = ../.;
    fileset = unions [
      ../buf.yaml
      ../proto
    ];
  };
in
{
  flake.packages = { inherit proto-hs proto-descriptor; };

  flake.output.checks.proto-check =
    pkgs.runCommandLocal "proto-check" { nativeBuildInputs = [ pkgs.buf ]; }
      ''
        cd ${bufSource}
        export HOME="$TMPDIR"
        buf lint
        buf format --diff --exit-code
        buf breaking --against ${contract-main}
        touch $out
      '';

  tasks.codegen = {
    description = "Materialise the generated protobuf code into the tree for editors";
    body = ''
      set -euo pipefail
      cd "$(${pkgs.git}/bin/git rev-parse --show-toplevel)"
      rm -rf backend/proto/gen
      mkdir -p backend/proto/gen
      cp -r ${config.flake.packages.proto-hs}/Proto backend/proto/gen/
      chmod -R u+w backend/proto/gen
    '';
  };
}
