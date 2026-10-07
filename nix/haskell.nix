{
  config,
  lib,
  peculiar-rpc,
  pkgs,
  ...
}:
let
  haskellPackages = import "${peculiar-rpc}/nix/haskell-packages.nix" { inherit lib pkgs; };
  inherit (lib.fileset) toSource unions;
  inherit (pkgs.haskell.lib.compose) dontHaddock;

  lean = dontHaddock;

  rpc = peculiar-rpc.packages.${pkgs.stdenv.hostPlatform.system};

  symbolicator = config.flake.packages.peculiar-insights-symbolicator;

  coreSource = toSource {
    root = ../backend/core;
    fileset = unions [
      ../backend/core/peculiar-insights-core.cabal
      ../backend/core/LICENSE
      ../backend/core/src
      ../backend/core/test
    ];
  };

  corePackage =
    {
      mkDerivation,
      aeson,
      base,
      base16-bytestring,
      containers,
      cryptohash-sha256,
      deriving-aeson,
      hedgehog,
      optics-core,
      scientific,
      text,
      time,
      uuid-types,
    }:
    mkDerivation {
      pname = "peculiar-insights-core";
      version = "0.1.0.0";
      src = coreSource;
      libraryHaskellDepends = [
        aeson
        base
        base16-bytestring
        containers
        cryptohash-sha256
        deriving-aeson
        optics-core
        scientific
        text
        time
        uuid-types
      ];
      testHaskellDepends = [
        aeson
        base
        containers
        hedgehog
        optics-core
        text
        time
        uuid-types
      ];
      license = lib.licenses.mit;
    };

  protoFiles = toSource {
    root = ../backend/proto;
    fileset = unions [
      ../backend/proto/peculiar-insights-proto.cabal
      ../backend/proto/LICENSE
    ];
  };

  protoSource = pkgs.runCommandLocal "peculiar-insights-proto-src" { } ''
    cp -r ${protoFiles} "$out"
    chmod -R u+w "$out"
    mkdir -p "$out/gen"
    cp -r ${config.flake.packages.proto-hs}/Proto "$out/gen/"
  '';

  protoPackage =
    {
      mkDerivation,
      base,
      proto-lens-protobuf-types,
      proto-lens-runtime,
    }:
    mkDerivation {
      pname = "peculiar-insights-proto";
      version = "0.1.0.0";
      src = protoSource;
      libraryHaskellDepends = [
        base
        proto-lens-protobuf-types
        proto-lens-runtime
      ];
      license = lib.licenses.mit;
    };

  serverSource = toSource {
    root = ../.;
    fileset = unions [
      ../grafana/dashboards
      ../grafana/alerting
      ../backend/server/peculiar-insights-server.cabal
      ../backend/server/LICENSE
      ../backend/server/src
      ../backend/server/app
      ../backend/server/test
      ../backend/server/migrations
    ];
  };

  serverPackage =
    {
      mkDerivation,
      aeson,
      async,
      base,
      bytestring,
      containers,
      beam-core,
      beam-postgres,
      deriving-aeson,
      directory,
      extra,
      file-embed,
      hedgehog,
      http-client-tls,
      http-types,
      jose,
      lens-family,
      optics-core,
      peculiar-insights-core,
      peculiar-insights-proto,
      peculiar-rpc,
      postgresql-simple,
      process,
      proto-lens,
      proto-lens-protobuf-types,
      proto-lens-runtime,
      resource-pool,
      temporary,
      filepath,
      http-client,
      text,
      time,
      uuid-types,
      wai,
      warp,
    }:
    mkDerivation {
      pname = "peculiar-insights-server";
      version = "0.1.0.0";
      src = serverSource;
      sourceRoot = "source/backend/server";
      isLibrary = true;
      isExecutable = true;
      libraryHaskellDepends = [
        aeson
        async
        base
        bytestring
        containers
        beam-core
        beam-postgres
        directory
        extra
        file-embed
        filepath
        http-client
        http-client-tls
        http-types
        jose
        lens-family
        optics-core
        peculiar-insights-core
        peculiar-insights-proto
        peculiar-rpc
        postgresql-simple
        process
        proto-lens
        proto-lens-protobuf-types
        resource-pool
        temporary
        text
        time
        uuid-types
        wai
        warp
      ];
      executableHaskellDepends = [
        base
        text
      ];
      testHaskellDepends = [
        aeson
        async
        base
        bytestring
        containers
        deriving-aeson
        file-embed
        filepath
        hedgehog
        http-client
        http-types
        jose
        lens-family
        peculiar-insights-core
        peculiar-insights-proto
        peculiar-rpc
        postgresql-simple
        process
        proto-lens
        temporary
        text
        time
        uuid-types
        warp
      ];
      testToolDepends = [ pkgs.postgresql ];
      buildTools = [ pkgs.makeWrapper ];
      preCheck = ''
        export PECULIAR_INSIGHTS_SYMBOLICATOR=${lib.getExe symbolicator}
        export PECULIAR_INSIGHTS_UPLOAD=${config.flake.output.apps.peculiar-insights-upload-symbols.program}
        export PECULIAR_INSIGHTS_FIXTURES=${config.flake.packages.symbol-fixtures}
      '';
      postInstall = ''
        wrapProgram "$out/bin/peculiar-insights-server" --set-default PECULIAR_INSIGHTS_SYMBOLICATOR ${lib.getExe symbolicator}
      '';
      license = lib.licenses.mit;
      mainProgram = "peculiar-insights-server";
    };

  core = lean (haskellPackages.callPackage corePackage { });

  proto = lean (haskellPackages.callPackage protoPackage { });

  server = lean (
    haskellPackages.callPackage serverPackage {
      peculiar-insights-core = core;
      peculiar-insights-proto = proto;
      peculiar-rpc = rpc.peculiar-rpc;
    }
  );

  uploadSource = toSource {
    root = ../backend/upload;
    fileset = unions [
      ../backend/upload/peculiar-insights-upload.cabal
      ../backend/upload/LICENSE
      ../backend/upload/src
      ../backend/upload/app
      ../backend/upload/test
    ];
  };

  uploadPackage =
    {
      mkDerivation,
      base,
      bytestring,
      directory,
      filepath,
      hedgehog,
      lens-family,
      optparse-applicative,
      peculiar-insights-core,
      peculiar-insights-proto,
      peculiar-rpc-client,
      proto-lens,
      temporary,
      text,
    }:
    mkDerivation {
      pname = "peculiar-insights-upload";
      version = "0.1.0.0";
      src = uploadSource;
      isLibrary = true;
      isExecutable = true;
      libraryHaskellDepends = [
        base
        bytestring
        directory
        filepath
        lens-family
        optparse-applicative
        peculiar-insights-core
        peculiar-insights-proto
        peculiar-rpc-client
        proto-lens
        text
      ];
      executableHaskellDepends = [ base ];
      testHaskellDepends = [
        base
        directory
        filepath
        hedgehog
        peculiar-insights-core
        temporary
      ];
      license = lib.licenses.mit;
      mainProgram = "peculiar-insights-upload-symbols";
    };

  upload = lean (
    haskellPackages.callPackage uploadPackage {
      peculiar-insights-core = core;
      peculiar-insights-proto = proto;
      peculiar-rpc-client = rpc.peculiar-rpc-client;
    }
  );

  sdkSource = toSource {
    root = ../sdk/haskell;
    fileset = unions [
      ../sdk/haskell/peculiar-insights-sdk.cabal
      ../sdk/haskell/LICENSE
      ../sdk/haskell/src
      ../sdk/haskell/example
      ../sdk/haskell/test
    ];
  };

  sdkPackage =
    {
      mkDerivation,
      async,
      base,
      bytestring,
      containers,
      directory,
      filepath,
      hedgehog,
      lens-family,
      peculiar-insights-proto,
      peculiar-rpc,
      proto-lens,
      proto-lens-protobuf-types,
      stm,
      temporary,
      text,
      time,
      uuid,
    }:
    mkDerivation {
      pname = "peculiar-insights-sdk";
      version = "0.1.0.0";
      src = sdkSource;
      libraryHaskellDepends = [
        async
        base
        bytestring
        containers
        directory
        filepath
        lens-family
        peculiar-insights-proto
        peculiar-rpc
        proto-lens
        proto-lens-protobuf-types
        stm
        text
        time
        uuid
      ];
      isLibrary = true;
      isExecutable = true;
      executableHaskellDepends = [
        base
        text
      ];
      testHaskellDepends = [
        async
        base
        bytestring
        containers
        filepath
        hedgehog
        lens-family
        peculiar-insights-proto
        peculiar-rpc
        proto-lens
        stm
        temporary
        text
        time
      ];
      license = lib.licenses.mit;
      mainProgram = "peculiar-insights-example";
    };

  sdk = lean (
    haskellPackages.callPackage sdkPackage {
      peculiar-insights-proto = proto;
      peculiar-rpc = rpc.peculiar-rpc;
    }
  );
in
{
  flake.packages = {
    default = server;
    peculiar-insights-core = core;
    peculiar-insights-proto = proto;
    peculiar-insights-server = server;
    peculiar-insights-sdk = sdk;
    peculiar-insights-upload = upload;
  };

  flake.apps.peculiar-insights-upload-symbols = upload;
}
