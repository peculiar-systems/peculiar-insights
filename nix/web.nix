{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.fileset) toSource unions;

  root = ../sdk/ts;

  src = toSource {
    inherit root;
    fileset = unions [
      (root + "/package.json")
      (root + "/package-lock.json")
      (root + "/tsconfig.json")
      (root + "/tsconfig.build.json")
      (root + "/buf.gen.yaml")
      (root + "/.oxlintrc.json")
      (root + "/.oxfmtrc.json")
      (root + "/src")
    ];
  };

  protoSource = toSource {
    root = ../proto;
    fileset = ../proto;
  };

  nodejs = pkgs.nodejs_24;

  npmDeps = pkgs.fetchNpmDeps {
    inherit src;
    name = "peculiar-insights-ts-npm-deps";
    hash = "sha256-OoMIsBsG1clCsP1YhgliiJcxsp5UJkbf1xDxkOX7D+o=";
  };

  sdk = pkgs.buildNpmPackage {
    pname = "peculiar-insights-ts";
    version = "0.1.0";
    inherit src npmDeps nodejs;
    nativeBuildInputs = [ pkgs.buf ];
    npmBuildScript = "build";
    dontNpmInstall = true;
    preBuild = ''
      export HOME="$TMPDIR"
      buf generate ${protoSource}
      npm run check
      npm run lint
      npm run fmt:check
      npm test
    '';
    installPhase = ''
      runHook preInstall
      mkdir -p "$out"
      cp -r dist/. "$out/"
      runHook postInstall
    '';
  };
in
{
  flake.packages.peculiar-insights-ts = sdk;

  flake.output.checks.web-check = sdk;

  tasks.web-codegen = {
    description = "Materialise the generated protobuf code for the TypeScript SDK into the tree";
    body = ''
      set -euo pipefail
      cd "$(${pkgs.git}/bin/git rev-parse --show-toplevel)/sdk/ts"
      export HOME="''${TMPDIR:-/tmp}"
      ${nodejs}/bin/npm ci --no-fund --no-audit
      ${pkgs.buf}/bin/buf generate
    '';
  };
}
