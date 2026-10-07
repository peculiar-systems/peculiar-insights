{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (pkgs) haskellPackages;
  inherit (lib.fileset) toSource unions;
  inherit (pkgs.haskell.lib.compose) disableLibraryProfiling dontHaddock;

  source = toSource {
    root = ../backend/inventory;
    fileset = unions [
      ../backend/inventory/peculiar-insights-inventory.cabal
      ../backend/inventory/LICENSE
      ../backend/inventory/src
      ../backend/inventory/app
      ../backend/inventory/test
    ];
  };

  package =
    {
      mkDerivation,
      aeson,
      base,
      bytestring,
      containers,
      deriving-aeson,
      hedgehog,
      lens-family,
      proto-lens,
      proto-lens-protobuf-types,
      text,
    }:
    mkDerivation {
      pname = "peculiar-insights-inventory";
      version = "0.1.0.0";
      src = source;
      isLibrary = true;
      isExecutable = true;
      libraryHaskellDepends = [
        aeson
        base
        bytestring
        containers
        deriving-aeson
        lens-family
        proto-lens
        proto-lens-protobuf-types
        text
      ];
      executableHaskellDepends = [
        aeson
        base
        bytestring
        text
      ];
      testHaskellDepends = [
        base
        hedgehog
        lens-family
        proto-lens
        proto-lens-protobuf-types
        text
      ];
      license = lib.licenses.mit;
      mainProgram = "peculiar-insights-inventory";
    };

  inventory = disableLibraryProfiling (dontHaddock (haskellPackages.callPackage package { }));

  descriptor = config.flake.packages.proto-descriptor;

  accessedApi = ../privacy/accessed-api.json;

  generated = pkgs.runCommandLocal "peculiar-insights-inventory-files" { } ''
    mkdir -p "$out"
    ${inventory}/bin/peculiar-insights-inventory ${descriptor}/insights.binpb ${accessedApi} "$out/PRIVACY.md" "$out/PrivacyInfo.xcprivacy"
  '';

  manifestPath = "sdk/dart/peculiar_insights_flutter/ios/Resources/PrivacyInfo.xcprivacy";

  committed = toSource {
    root = ../.;
    fileset = unions [
      ../PRIVACY.md
      (../. + "/${manifestPath}")
    ];
  };
in
{
  flake.packages = {
    peculiar-insights-inventory = inventory;
    inventory-files = generated;
  };

  flake.output.checks.inventory-check = pkgs.runCommandLocal "inventory-check" { } ''
    cmp ${generated}/PRIVACY.md ${committed}/PRIVACY.md
    cmp ${generated}/PrivacyInfo.xcprivacy ${committed}/${manifestPath}
    touch $out
  '';

  tasks.inventory = {
    description = "Regenerate PRIVACY.md and the Apple privacy manifest from the proto annotations";
    body = ''
      set -euo pipefail
      cd "$(${pkgs.git}/bin/git rev-parse --show-toplevel)"
      cp ${generated}/PRIVACY.md PRIVACY.md
      mkdir -p "$(dirname ${manifestPath})"
      cp ${generated}/PrivacyInfo.xcprivacy ${manifestPath}
      chmod u+w PRIVACY.md ${manifestPath}
    '';
  };
}
