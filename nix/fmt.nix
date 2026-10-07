{
  ai-haskell-linter,
  lib,
  pkgs,
  ...
}:
let
  inherit (ai-haskell-linter.packages.${pkgs.stdenv.hostPlatform.system}) fourmolu fourmolu-config;
  inherit (pkgs) git nixfmt;
  inherit (lib.fileset) toSource unions;

  root = ../.;

  directories = [
    "backend/core/src"
    "backend/core/test"
    "backend/server/src"
    "backend/server/app"
    "backend/server/test"
    "backend/upload/src"
    "backend/upload/app"
    "backend/upload/test"
    "backend/inventory/src"
    "backend/inventory/app"
    "backend/inventory/test"
    "sdk/haskell/src"
    "sdk/haskell/test"
    "sdk/haskell/example"
  ];

  nixFiles = "flake.nix nix/*.nix nixos/*.nix";

  formatHaskell =
    mode:
    "LANG=C.UTF-8 ${fourmolu}/bin/fourmolu --config ${fourmolu-config} --mode ${mode} ${lib.concatStringsSep " " directories}";

  formatNix = arguments: "${nixfmt}/bin/nixfmt ${arguments} ${nixFiles}";

  formatRust =
    arguments:
    "${pkgs.rustfmt}/bin/rustfmt --edition 2024 ${arguments} adapters/symbolicator/build.rs adapters/symbolicator/src/main.rs";

  source = toSource {
    inherit root;
    fileset = unions (
      [
        (root + "/flake.nix")
        (root + "/nix")
        (root + "/nixos")
        (root + "/backend/core/peculiar-insights-core.cabal")
        (root + "/backend/server/peculiar-insights-server.cabal")
        (root + "/backend/inventory/peculiar-insights-inventory.cabal")
        (root + "/backend/upload/peculiar-insights-upload.cabal")
        (root + "/sdk/haskell/peculiar-insights-sdk.cabal")
        (root + "/adapters/symbolicator/build.rs")
        (root + "/adapters/symbolicator/src")
      ]
      ++ map (directory: root + "/${directory}") directories
    );
  };
in
{
  flake.output.checks.fmt-check = pkgs.runCommandLocal "fmt-check" { } ''
    cd ${source}
    ${formatHaskell "check"}
    ${formatNix "--check"}
    ${formatRust "--check"}
    touch $out
  '';

  tasks.fmt = {
    description = "Format the Haskell, the Nix and the Rust in place";
    body = ''
      set -euo pipefail
      cd "$(${git}/bin/git rev-parse --show-toplevel)"
      ${formatHaskell "inplace"}
      ${formatNix ""}
      ${formatRust ""}
    '';
  };
}
