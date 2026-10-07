{
  config,
  lib,
  peculiar-rpc,
  pkgs,
  ...
}:
let
  haskellPackages = import "${peculiar-rpc}/nix/haskell-packages.nix" { inherit lib pkgs; };

  local = [
    "peculiar-insights-core"
    "peculiar-insights-proto"
    "peculiar-insights-server"
    "peculiar-insights-sdk"
    "peculiar-insights-upload"
  ];

  dependencies =
    package:
    builtins.filter (
      input: !(builtins.elem (input.pname or "") local)
    ) package.getBuildInputs.haskellBuildInputs;

  ghc = haskellPackages.ghcWithPackages (
    _:
    lib.concatMap dependencies (
      with config.flake.packages;
      [
        peculiar-insights-core
        peculiar-insights-proto
        peculiar-insights-server
        peculiar-insights-sdk
        peculiar-insights-upload
      ]
    )
  );
in
{
  flake.shell = [
    ghc
    haskellPackages.cabal-install
    pkgs.git
    pkgs.buf
    pkgs.postgresql
  ];
}
