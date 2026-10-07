{
  config,
  lib,
  pkgs,
  ...
}:
let
  evaluate =
    extra:
    import (pkgs.path + "/nixos/lib/eval-config.nix") {
      system = null;
      modules = [
        ../nixos/module.nix
        ../nix/fixtures/module-sample.nix
        { nixpkgs.hostPlatform = "x86_64-linux"; }
        extra
      ];
    };

  sample = evaluate { };

  rejected = evaluate {
    services.peculiar-insights.projects.shop.environments.prod.analytics.funnels."Bad-Name".steps = [
      "one"
    ];
  };

  insights = sample.config.services.peculiar-insights;

  rendered = pkgs.writeText "module-config.json" (builtins.toJSON insights.configuration);

  dashboards = pkgs.runCommandLocal "module-dashboards" { } (
    ''
      mkdir -p "$out"
    ''
    + lib.concatStrings (
      lib.mapAttrsToList (name: dashboard: ''
        cp ${pkgs.writeText "${name}.json" (builtins.toJSON dashboard)} "$out/${name}.json"
      '') insights.dashboardFiles
    )
  );

  expectedKeys = {
    "shop/prod" = "/var/lib/peculiar-insights/keys/shop-prod";
    "shop/staging" = "/run/secrets/shop-staging-key";
    "notes/prod" = "/var/lib/peculiar-insights/keys/notes-prod";
  };

  expectedUploadKeys = {
    shop = "/var/lib/peculiar-insights/upload-keys/shop";
    notes = "/run/secrets/notes-upload-key";
  };

  failing = builtins.filter (assertion: !assertion.assertion) rejected.config.assertions;

  verified =
    assert lib.assertMsg (insights.keyFiles == expectedKeys) "keyFiles differ from the expected paths";
    assert lib.assertMsg (
      insights.uploadKeyFiles == expectedUploadKeys
    ) "uploadKeyFiles differ from the expected paths";
    assert lib.assertMsg (
      insights.configuration.symbols.max_upload_bytes == 1024 * 1024 * 1024
    ) "the symbols upload cap is 1 GiB when unset";
    assert lib.assertMsg (
      builtins.attrNames insights.dashboardFiles == [ "shop-prod" ]
    ) "exactly the environment declaring analytics gets a dashboard";
    assert lib.assertMsg (failing != [ ]) "a bad funnel name must fail an assertion";
    assert lib.assertMsg (
      !builtins.any (
        package: lib.getName package == "peculiar-insights"
      ) sample.config.environment.systemPackages
    ) "the module installs no peculiar-insights command";
    assert lib.assertMsg (
      builtins.length sample.config.services.grafana.provision.dashboards.settings.providers == 2
    ) "one shared provider plus one per declaring environment";
    true;
in
{
  flake.packages.module-rendered = pkgs.runCommandLocal "module-rendered" { } ''
    mkdir -p "$out"
    cp ${rendered} "$out/config.json"
    cp -r ${dashboards} "$out/dashboards"
  '';

  flake.output.checks.module-check =
    pkgs.runCommandLocal "module-check"
      {
        nativeBuildInputs = [ pkgs.jq ];
        passthru.verified = verified;
      }
      ''
        ${lib.optionalString verified ""}
        cmp ${rendered} ${../nix/fixtures/module-config.json}
        ${lib.getExe config.flake.packages.peculiar-insights-server} --check ${rendered}
        test ! -e ${config.flake.packages.peculiar-insights-server}/bin/peculiar-insights-admin
        for file in ${dashboards}/*.json; do
          jq -e '.uid and .panels and (.panels | length > 0)' "$file" > /dev/null
        done
        touch $out
      '';

  tasks.module-fixture = {
    description = "Regenerate the expected configuration JSON of the NixOS module check";
    body = ''
      set -euo pipefail
      cd "$(${pkgs.git}/bin/git rev-parse --show-toplevel)"
      cp "$(${pkgs.nix}/bin/nix build --no-link --print-out-paths .#module-rendered)/config.json" nix/fixtures/module-config.json
      chmod u+w nix/fixtures/module-config.json
    '';
  };
}
