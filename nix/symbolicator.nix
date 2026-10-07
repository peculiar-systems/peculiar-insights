{
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.fileset) toSource unions;

  root = ../.;

  source = toSource {
    inherit root;
    fileset = unions [
      (root + "/adapters/symbolicator/Cargo.toml")
      (root + "/adapters/symbolicator/Cargo.lock")
      (root + "/adapters/symbolicator/build.rs")
      (root + "/adapters/symbolicator/src")
      (root + "/proto/peculiar/insights/v1/symbolicator.proto")
    ];
  };

  attributes = {
    pname = "peculiar-insights-symbolicator";
    version = "0.1.0";
    src = source;
    buildAndTestSubdir = "adapters/symbolicator";
    cargoRoot = "adapters/symbolicator";
    cargoLock.lockFile = ../adapters/symbolicator/Cargo.lock;
    nativeBuildInputs = [ pkgs.protobuf ];
    meta = {
      license = lib.licenses.mit;
      mainProgram = "peculiar-insights-symbolicator";
    };
  };

  symbolicator = pkgs.rustPlatform.buildRustPackage attributes;

  clippy = pkgs.rustPlatform.buildRustPackage (
    attributes
    // {
      pname = "peculiar-insights-symbolicator-clippy";
      nativeBuildInputs = attributes.nativeBuildInputs ++ [ pkgs.clippy ];
      buildPhase = ''
        runHook preBuild
        (cd adapters/symbolicator && cargo clippy --offline --all-targets -- -D warnings)
        runHook postBuild
      '';
      doCheck = false;
      installPhase = ''
        touch $out
      '';
    }
  );
in
{
  flake.packages.peculiar-insights-symbolicator = symbolicator;

  flake.output.checks = {
    peculiar-insights-symbolicator = symbolicator;
    symbolicator-clippy = clippy;
  };
}
