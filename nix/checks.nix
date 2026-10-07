{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (pkgs.haskell.lib.compose) appendConfigureFlag doCheck;

  tested = lib.flip lib.pipe [
    doCheck
    (appendConfigureFlag "--ghc-option=-Werror")
  ];
in
{
  flake.output.checks = {
    peculiar-insights-core-test = tested config.flake.packages.peculiar-insights-core;
    peculiar-insights-server-test = tested config.flake.packages.peculiar-insights-server;
    peculiar-insights-inventory-test = tested config.flake.packages.peculiar-insights-inventory;
    peculiar-insights-sdk-test = tested config.flake.packages.peculiar-insights-sdk;
    peculiar-insights-upload-test = tested config.flake.packages.peculiar-insights-upload;
  };
}
