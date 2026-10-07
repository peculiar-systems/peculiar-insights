{
  description = "Self-hosted product analytics and crash tracking, served over gRPC and read through Grafana";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    core-flake = {
      url = "github:purplenoodlesoop/core-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ai-haskell-linter = {
      url = "github:purplenoodlesoop/ai_haskell_linter";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    peculiar-rpc = {
      url = "github:peculiar-systems/peculiar-rpc";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.core-flake.follows = "core-flake";
      inputs.ai-haskell-linter.follows = "ai-haskell-linter";
    };
    contract-main = {
      url = "github:peculiar-systems/peculiar-insights/main";
      flake = false;
    };
  };

  outputs =
    {
      self,
      ai-haskell-linter,
      core-flake,
      peculiar-rpc,
      contract-main,
      ...
    }:
    core-flake.lib.evalFlake {
      specialArgs = {
        inherit
          ai-haskell-linter
          peculiar-rpc
          contract-main
          ;
      };

      perSystem.imports = [
        core-flake.nixosModules.tasks
        ./nix/proto.nix
        ./nix/symbolicator.nix
        ./nix/symbol-fixtures.nix
        ./nix/haskell.nix
        ./nix/inventory.nix
        ./nix/web.nix
        ./nix/dart.nix
        ./nix/website.nix
        ./nix/module-check.nix
        ./nix/grafana-check.nix
        ./nix/checks.nix
        ./nix/lint.nix
        ./nix/fmt.nix
        ./nix/shell.nix
      ];

      topLevel.nixosModules = rec {
        peculiar-insights =
          { lib, pkgs, ... }:
          {
            imports = [ ./nixos/module.nix ];
            services.peculiar-insights = {
              package = lib.mkDefault self.packages.${pkgs.stdenv.hostPlatform.system}.peculiar-insights-server;
              grafana.dashboards = lib.mkDefault ./grafana/dashboards;
              grafana.alerting = lib.mkDefault ./grafana/alerting;
            };
          };
        website =
          { lib, pkgs, ... }:
          {
            imports = [ ./nixos/website.nix ];
            services.peculiar-insights-website.package =
              lib.mkDefault
                self.packages.${pkgs.stdenv.hostPlatform.system}.website;
          };
        default = peculiar-insights;
      };
    };
}
