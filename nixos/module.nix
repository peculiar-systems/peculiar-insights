{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    mkMerge
    types
    mapAttrsToList
    concatLists
    concatMap
    optional
    filterAttrs
    listToAttrs
    nameValuePair
    ;

  cfg = config.services.peculiar-insights;

  credentialsDirectory = "/run/credentials/peculiar-insights.service";

  stateDirectory = "/var/lib/peculiar-insights";

  credentialName = slug: environment: "key-${slug}-${environment}";

  generatedKey = slug: environment: "${stateDirectory}/keys/${slug}-${environment}";

  dashboardsLibrary = import ./dashboards.nix { inherit lib; };

  identifier = name: builtins.match "[a-z][a-z0-9_]{0,47}" name != null;

  environments = concatLists (
    mapAttrsToList (
      slug: project:
      mapAttrsToList (environment: env: { inherit slug environment env; }) project.environments
    ) cfg.projects
  );

  filtersType = types.attrsOf (
    types.oneOf [
      types.str
      types.int
      types.float
      types.bool
    ]
  );

  matcherType = types.submodule {
    options = {
      event = mkOption {
        type = types.str;
        description = "Event name";
      };
      filters = mkOption {
        type = filtersType;
        default = { };
        description = "Property values the event must carry to match";
      };
    };
  };

  stepType = types.submodule {
    options = {
      event = mkOption {
        type = types.str;
        description = "Event name";
      };
      filters = mkOption {
        type = filtersType;
        default = { };
        description = "Property values the event must carry to count as this step";
      };
      label = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "What the step is called in the dashboard; null names it after the event and its filters";
      };
    };
  };

  described =
    event: filters:
    if filters == { } then
      event
    else
      "${event} (${
        lib.concatStringsSep ", " (mapAttrsToList (key: value: "${key}=${builtins.toJSON value}") filters)
      })";

  matching =
    given:
    if builtins.isString given then
      {
        event = given;
        filters = { };
      }
    else
      { inherit (given) event filters; };

  stepping =
    given:
    let
      matched = matching given;
    in
    matched
    // {
      label =
        if builtins.isString given || given.label == null then
          described matched.event matched.filters
        else
          given.label;
    };

  funnelType = types.submodule {
    options = {
      steps = mkOption {
        type = types.listOf (types.either types.str stepType);
        description = "Steps in order, each an event name or an event with the property values it must carry; a person converts by performing them in this order within the window";
      };
      windowDays = mkOption {
        type = types.ints.positive;
        default = 7;
        description = "Days a person has to reach the last step after the first";
      };
      lookbackDays = mkOption {
        type = types.ints.positive;
        default = 90;
        description = "Days of history the reporting view covers";
      };
    };
  };

  retentionType = types.submodule {
    options = {
      birth = mkOption {
        type = types.either types.str matcherType;
        description = "Event that starts a person's cohort, by name or with the property values it must carry";
      };
      returnEvent = mkOption {
        type = types.either types.str matcherType;
        description = "Event that counts as returning, by name or with the property values it must carry";
      };
      period = mkOption {
        type = types.enum [
          "day"
          "week"
          "month"
        ];
        default = "week";
        description = "Cohort and period granularity";
      };
      periods = mkOption {
        type = types.ints.positive;
        default = 8;
        description = "Number of periods after birth to report";
      };
      lookbackDays = mkOption {
        type = types.ints.positive;
        default = 180;
        description = "Days of history the reporting view covers";
      };
    };
  };

  metricType = types.submodule {
    options = {
      event = mkOption {
        type = types.str;
        description = "Event name counted by the metric";
      };
      filters = mkOption {
        type = filtersType;
        default = { };
        description = "Property values the event must carry to count";
      };
      measure = mkOption {
        default = null;
        description = "A numeric property to aggregate per day beside the counts; events where it is absent or not a number are left out of the aggregate";
        type = types.nullOr (
          types.submodule {
            options = {
              property = mkOption {
                type = types.str;
                description = "Property key holding the number";
              };
              aggregate = mkOption {
                type = types.enum [
                  "sum"
                  "average"
                  "minimum"
                  "maximum"
                  "median"
                  "p95"
                  "p99"
                ];
                default = "sum";
                description = "How a day's values become one";
              };
            };
          }
        );
      };
    };
  };

  rateType = types.submodule {
    options = {
      perMinute = mkOption {
        type = types.ints.positive;
        default = 6000;
        description = "Items admitted per minute, sustained";
      };
      burst = mkOption {
        type = types.ints.positive;
        default = 12000;
        description = "Items admitted at once after a quiet spell";
      };
    };
  };

  analyticsType = types.submodule {
    options = {
      funnels = mkOption {
        type = types.attrsOf funnelType;
        default = { };
        description = "Named funnels, each a reporting view and a dashboard panel";
      };
      retention = mkOption {
        type = types.attrsOf retentionType;
        default = { };
        description = "Named retention analyses, each a reporting view and a dashboard panel";
      };
      metrics = mkOption {
        type = types.attrsOf metricType;
        default = { };
        description = "Named daily counts of one event, each a reporting view and a dashboard panel";
      };
    };
  };

  conditionType = types.attrTag {
    person_property = mkOption {
      description = "The person has a property equal to a value";
      type = types.submodule {
        options = {
          key = mkOption {
            type = types.str;
            description = "Property key";
          };
          equals = mkOption {
            type = types.anything;
            description = "The value the property must hold";
          };
        };
      };
    };
    did_event = mkOption {
      description = "The person performed an event at least N times within a window";
      type = types.submodule {
        options = {
          event = mkOption {
            type = types.str;
            description = "Event name";
          };
          filters = mkOption {
            type = filtersType;
            default = { };
            description = "Property values the event must carry to count";
          };
          at_least = mkOption {
            type = types.ints.positive;
            default = 1;
            description = "Minimum count";
          };
          within_days = mkOption {
            type = types.ints.positive;
            default = 30;
            description = "Window in days, counted back from now";
          };
        };
      };
    };
    did_not_event = mkOption {
      description = "The person did not perform an event within a window";
      type = types.submodule {
        options = {
          event = mkOption {
            type = types.str;
            description = "Event name";
          };
          filters = mkOption {
            type = filtersType;
            default = { };
            description = "Property values the event must carry to count";
          };
          within_days = mkOption {
            type = types.ints.positive;
            default = 30;
            description = "Window in days, counted back from now";
          };
        };
      };
    };
  };

  environmentType = types.submodule {
    options = {
      keyFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to a file holding the write-only ingest key for this environment, delivered out of band; null lets the service generate one under its state directory";
      };
      retentionDays = mkOption {
        type = types.nullOr types.ints.positive;
        default = null;
        description = "Delete events, crashes and sessions older than this many days; null keeps everything";
      };
      rateLimit = mkOption {
        type = types.nullOr rateType;
        default = { };
        description = "How many items the environment's key may send; past it a call is refused with the delay to retry after, and the SDKs keep what they were sending. null lifts the limit";
      };
      denylist = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Property keys the server drops before storing";
      };
      cohorts = mkOption {
        type = types.attrsOf (types.listOf conditionType);
        default = { };
        description = "Named cohorts, each a conjunction of conditions, materialised as reporting views";
      };
      analytics = mkOption {
        type = analyticsType;
        default = { };
        description = "Funnels, retention and metrics declared for this environment, materialised as reporting views and a Grafana dashboard in the project's folder";
      };
    };
  };

  projectType = types.submodule {
    options = {
      environments = mkOption {
        type = types.attrsOf environmentType;
        description = "Environments of the project, such as prod and staging";
      };
      uploadKeyFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to a file holding the key the project's build presents to upload its symbols, delivered out of band; null lets the service generate one under its state directory";
      };
    };
  };

  uploadCredentialName = slug: "upload-key-${slug}";

  generatedUploadKey = slug: "${stateDirectory}/upload-keys/${slug}";

  uploadKeyFiles = lib.mapAttrs (
    slug: project:
    if project.uploadKeyFile == null then generatedUploadKey slug else project.uploadKeyFile
  ) cfg.projects;

  uploadKeyPath =
    slug: project:
    if project.uploadKeyFile == null then
      generatedUploadKey slug
    else
      "${credentialsDirectory}/${uploadCredentialName slug}";

  uploadCredentials = mapAttrsToList (
    slug: project: "${uploadCredentialName slug}:${project.uploadKeyFile}"
  ) (filterAttrs (_: project: project.uploadKeyFile != null) cfg.projects);

  generatedUploadKeys = builtins.attrNames (
    filterAttrs (_: project: project.uploadKeyFile == null) cfg.projects
  );

  keyPath =
    {
      slug,
      environment,
      env,
    }:
    if env.keyFile == null then
      generatedKey slug environment
    else
      "${credentialsDirectory}/${credentialName slug environment}";

  projects = map (
    entry@{
      slug,
      environment,
      env,
    }:
    {
      inherit slug environment;
      key_file = keyPath entry;
      retention_days = env.retentionDays;
      rate_limit =
        if env.rateLimit == null then
          null
        else
          {
            per_minute = env.rateLimit.perMinute;
            inherit (env.rateLimit) burst;
          };
      denylist = env.denylist;
      cohorts = mapAttrsToList (name: conditions: { inherit name conditions; }) env.cohorts;
      analytics =
        let
          declared = normalized env.analytics;
        in
        {
          funnels = mapAttrsToList (name: funnel: {
            inherit name;
            inherit (funnel) steps;
            window_days = funnel.windowDays;
            lookback_days = funnel.lookbackDays;
          }) declared.funnels;
          retention = mapAttrsToList (name: retention: {
            inherit name;
            inherit (retention) birth period periods;
            return_event = retention.returnEvent;
            lookback_days = retention.lookbackDays;
          }) declared.retention;
          metrics = mapAttrsToList (name: metric: {
            inherit name;
            inherit (metric) event filters measure;
          }) declared.metrics;
        };
    }
  ) environments;

  normalized = analytics: {
    funnels = lib.mapAttrs (
      _: funnel: funnel // { steps = map stepping funnel.steps; }
    ) analytics.funnels;
    retention = lib.mapAttrs (
      _: retention:
      retention
      // {
        birth = matching retention.birth;
        returnEvent = matching retention.returnEvent;
      }
    ) analytics.retention;
    metrics = lib.mapAttrs (
      _: metric:
      metric
      // {
        measure = if metric.measure == null then null else { inherit (metric.measure) property aggregate; };
      }
    ) analytics.metrics;
  };

  keyFiles = listToAttrs (
    map (
      entry@{
        slug,
        environment,
        env,
      }:
      nameValuePair "${slug}/${environment}" (
        if env.keyFile == null then generatedKey slug environment else env.keyFile
      )
    ) environments
  );

  keyCredentials = concatMap (
    {
      slug,
      environment,
      env,
    }:
    optional (env.keyFile != null) "${credentialName slug environment}:${env.keyFile}"
  ) environments;

  generatedKeys = concatMap (
    {
      slug,
      environment,
      env,
    }:
    optional (env.keyFile == null) "${slug}-${environment}"
  ) environments;

  generateKeys = pkgs.writeShellScript "peculiar-insights-keys" ''
    set -euo pipefail
    generate() {
      directory="$STATE_DIRECTORY/$1"
      shift
      mkdir -p "$directory"
      chmod 0700 "$directory"
      for name in "$@"; do
        file="$directory/$name"
        if [ ! -e "$file" ]; then
          (umask 077; ${pkgs.openssl}/bin/openssl rand -hex 32 > "$file")
          chmod 0400 "$file"
        fi
      done
    }
    generate keys ${lib.escapeShellArgs generatedKeys}
    generate upload-keys ${lib.escapeShellArgs generatedUploadKeys}
  '';

  declared =
    {
      slug,
      environment,
      env,
    }:
    env.cohorts != { }
    || env.analytics.funnels != { }
    || env.analytics.retention != { }
    || env.analytics.metrics != { };

  dashboardFiles = listToAttrs (
    map (
      entry@{
        slug,
        environment,
        env,
      }:
      nameValuePair "${slug}-${environment}" (
        dashboardsLibrary.forEnvironment {
          inherit slug environment;
          inherit (env) cohorts;
          analytics = normalized env.analytics;
        }
      )
    ) (builtins.filter declared environments)
  );

  projectDashboards = lib.mapAttrs (
    name: dashboard: pkgs.writeTextDir "${name}.json" (builtins.toJSON dashboard)
  ) dashboardFiles;

  projectProviders = mapAttrsToList (
    name: directory:
    let
      entry = lib.findFirst (e: "${e.slug}-${e.environment}" == name) null environments;
    in
    {
      name = "peculiar-insights-${name}";
      folder = "Insights · ${entry.slug} / ${entry.environment}";
      options.path = directory;
      allowUiUpdates = false;
    }
  ) projectDashboards;

  names = concatMap (
    {
      slug,
      environment,
      env,
    }:
    [
      slug
      environment
    ]
    ++ builtins.attrNames env.cohorts
    ++ builtins.attrNames env.analytics.funnels
    ++ builtins.attrNames env.analytics.retention
    ++ builtins.attrNames env.analytics.metrics
  ) environments;

  shortFunnels = concatMap (
    { env, ... }:
    builtins.attrNames (filterAttrs (_: funnel: builtins.length funnel.steps < 2) env.analytics.funnels)
  ) environments;

  longFunnels = concatMap (
    { env, ... }:
    builtins.attrNames (
      filterAttrs (_: funnel: builtins.length funnel.steps > 60) env.analytics.funnels
    )
  ) environments;

  tlsCredentials =
    optional (cfg.listen.tls != null) "tls-certificate:${cfg.listen.tls.certificate}"
    ++ optional (cfg.listen.tls != null) "tls-key:${cfg.listen.tls.key}";

  configuration = {
    listen = {
      host = cfg.listen.host;
      port = cfg.listen.port;
      tls =
        if cfg.listen.tls == null then
          null
        else
          {
            certificate = "${credentialsDirectory}/tls-certificate";
            key = "${credentialsDirectory}/tls-key";
          };
      cors_origins = cfg.listen.corsOrigins;
    };
    monitoring = if cfg.monitoring.enable then { inherit (cfg.monitoring) host port; } else null;
    peer_limit =
      if cfg.peerLimit == null then
        null
      else
        {
          rate = {
            per_minute = cfg.peerLimit.perMinute;
            inherit (cfg.peerLimit) burst;
          };
          forwarded_header = cfg.peerLimit.forwardedHeader;
        };
    database = cfg.database.connection;
    reporting_role = cfg.reporting.role;
    symbols = {
      directory = "${stateDirectory}/symbols";
      max_upload_bytes = cfg.symbols.maxUploadBytes;
      upload_keys = mapAttrsToList (slug: project: {
        project = slug;
        key_file = uploadKeyPath slug project;
      }) cfg.projects;
    };
    grafana =
      if cfg.grafana.provision then
        {
          url = address (grafanaServer.protocol or "http") (grafanaServer.http_addr or "") (
            grafanaServer.http_port or 3000
          );
          organization = 1;
        }
      else
        null;
    inherit projects;
  };

  grafanaServer = config.services.grafana.settings.server;

  loopback =
    address:
    if address == "" || address == "0.0.0.0" then
      "127.0.0.1"
    else if address == "::" then
      "[::1]"
    else if lib.hasInfix ":" address then
      "[${address}]"
    else
      address;

  address =
    scheme: host: port:
    "${scheme}://${loopback host}:${toString port}";

  managementDatasource = "peculiar-insights-manage";

  configFile = pkgs.writeText "peculiar-insights.json" (builtins.toJSON configuration);

  dashboards = pkgs.runCommandLocal "peculiar-insights-dashboards" { } ''
    mkdir -p "$out"
    cp ${cfg.grafana.dashboards}/*.json "$out/"
  '';
in
{
  options.services.peculiar-insights = {
    enable = mkEnableOption "the Peculiar Insights analytics and crash tracking server";

    package = mkOption {
      type = types.package;
      description = "The server package";
    };

    listen = {
      host = mkOption {
        type = types.str;
        default = "127.0.0.1";
        description = "Address to bind";
      };
      port = mkOption {
        type = types.port;
        default = 50051;
        description = "Port serving gRPC, gRPC-Web and Connect";
      };
      corsOrigins = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Browser origins allowed to call the server; empty allows any origin";
      };
      tls = mkOption {
        type = types.nullOr (
          types.submodule {
            options = {
              certificate = mkOption {
                type = types.path;
                description = "Path to the PEM certificate chain, delivered out of band";
              };
              key = mkOption {
                type = types.path;
                description = "Path to the PEM private key, delivered out of band";
              };
            };
          }
        );
        default = null;
        description = "Serve TLS directly instead of behind a reverse proxy";
      };
    };

    monitoring = {
      enable = mkEnableOption "the Prometheus exposition of the server's own counters at /metrics";
      host = mkOption {
        type = types.str;
        default = "127.0.0.1";
        description = "Address the exposition binds";
      };
      port = mkOption {
        type = types.port;
        default = 9464;
        description = "Port the exposition listens on, apart from the one SDKs reach";
      };
    };

    peerLimit = mkOption {
      default = null;
      description = "How many items one network peer may send, whatever key it presents; null leaves peers unlimited. Behind a reverse proxy every call arrives from the proxy, so name the header it forwards the address in";
      type = types.nullOr (
        types.submodule {
          options = {
            perMinute = mkOption {
              type = types.ints.positive;
              default = 600;
              description = "Items admitted per minute from one peer, sustained";
            };
            burst = mkOption {
              type = types.ints.positive;
              default = 1200;
              description = "Items admitted at once from one peer after a quiet spell";
            };
            forwardedHeader = mkOption {
              type = types.nullOr types.str;
              default = null;
              example = "x-forwarded-for";
              description = "Header a trusted reverse proxy sets to the caller's address; null uses the address the connection came from";
            };
          };
        }
      );
    };

    database = {
      createLocally = mkOption {
        type = types.bool;
        default = true;
        description = "Run PostgreSQL on this host and create the database and roles";
      };
      connection = mkOption {
        type = types.str;
        default = "host=/run/postgresql dbname=peculiar-insights user=peculiar-insights";
        description = "libpq connection string; the default uses peer authentication over the local socket";
      };
    };

    reporting = {
      role = mkOption {
        type = types.str;
        default = "grafana";
        description = "PostgreSQL role granted read access to the reporting schema";
      };
    };

    grafana = {
      provision = mkOption {
        type = types.bool;
        default = true;
        description = "Provision the datasource, dashboards and alert rules into this host's Grafana";
      };
      dashboards = mkOption {
        type = types.path;
        description = "Directory holding the dashboard JSON files";
      };
      alerting = mkOption {
        type = types.path;
        description = "Directory holding the alert rule provisioning files";
      };
    };

    projects = mkOption {
      type = types.attrsOf projectType;
      default = { };
      description = "Projects and their environments, keyed by slug";
      example = {
        shop = {
          environments.prod = {
            retentionDays = 400;
            cohorts.payers = [
              {
                did_event = {
                  event = "purchase";
                  at_least = 1;
                  within_days = 30;
                };
              }
            ];
            analytics.funnels.checkout = {
              steps = [
                "checkout_opened"
                "order_placed"
              ];
              windowDays = 7;
            };
          };
        };
      };
    };

    symbols = {
      maxUploadBytes = mkOption {
        type = types.ints.positive;
        default = 1024 * 1024 * 1024;
        description = "Largest symbols upload, in bytes, summed over its files; a larger one is refused";
      };
    };

    keyFiles = mkOption {
      type = types.attrsOf types.path;
      readOnly = true;
      description = "The effective ingest key path of every environment, keyed slug/environment, generated or provided, for other services on this host to load as a credential";
    };

    uploadKeyFiles = mkOption {
      type = types.attrsOf types.path;
      readOnly = true;
      description = "The effective symbols upload key path of every project, keyed by slug, generated or provided, for a build on this host to load as a credential";
    };

    configuration = mkOption {
      type = types.attrs;
      readOnly = true;
      description = "The configuration the server is started with, as the attribute set that becomes its JSON file";
    };

    dashboardFiles = mkOption {
      type = types.attrsOf types.attrs;
      readOnly = true;
      description = "The generated Grafana dashboard of every environment that declares analytics or cohorts, keyed slug-environment";
    };
  };

  config = mkMerge [
    {
      services.peculiar-insights = {
        inherit
          keyFiles
          uploadKeyFiles
          configuration
          dashboardFiles
          ;
      };
    }
    (mkIf cfg.enable {
      assertions = [
        {
          assertion = builtins.all identifier names;
          message = "peculiar-insights: project slugs, environment, cohort, funnel, retention and metric names must be lowercase ascii letters, digits and underscores, start with a letter and be at most 48 characters; offending: ${
            lib.concatStringsSep ", " (builtins.filter (name: !identifier name) names)
          }";
        }
        {
          assertion = shortFunnels == [ ];
          message = "peculiar-insights: a funnel needs at least two steps; offending: ${lib.concatStringsSep ", " shortFunnels}";
        }
        {
          assertion = longFunnels == [ ];
          message = "peculiar-insights: a funnel has at most sixty steps; offending: ${lib.concatStringsSep ", " longFunnels}";
        }
      ];

      services.postgresql = mkIf cfg.database.createLocally {
        enable = true;
        ensureDatabases = [ "peculiar-insights" ];
        ensureUsers = [
          {
            name = "peculiar-insights";
            ensureDBOwnership = true;
          }
          { name = cfg.reporting.role; }
        ];
      };

      services.grafana.provision = mkIf cfg.grafana.provision {
        enable = true;
        datasources.settings.datasources = [
          {
            name = "Peculiar Insights";
            uid = "peculiar-insights";
            type = "postgres";
            url = "/run/postgresql";
            user = cfg.reporting.role;
            jsonData = {
              database = "peculiar-insights";
              sslmode = "disable";
              timescaledb = false;
            };
          }
          {
            name = "Peculiar Insights management";
            uid = managementDatasource;
            type = "graphite";
            access = "proxy";
            url = address (if cfg.listen.tls == null then "http" else "https") cfg.listen.host cfg.listen.port;
          }
        ];
        dashboards.settings.providers = [
          {
            name = "peculiar-insights";
            folder = "Peculiar Insights";
            options.path = dashboards;
            allowUiUpdates = false;
          }
        ]
        ++ projectProviders;
        alerting.rules.path = cfg.grafana.alerting;
      };
      services.grafana.settings.security.actions_allow_post_url =
        mkIf cfg.grafana.provision "/api/datasources/proxy/uid/${managementDatasource}/peculiar.insights.v1.Manage/*";

      systemd.services.peculiar-insights = {
        description = "Peculiar Insights ingest server";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ] ++ optional cfg.database.createLocally "postgresql.service";
        requires = optional cfg.database.createLocally "postgresql.service";
        serviceConfig = {
          ExecStartPre = generateKeys;
          ExecStart = "${cfg.package}/bin/peculiar-insights-server ${configFile}";
          StateDirectory = "peculiar-insights";
          StateDirectoryMode = "0750";
          Restart = "always";
          RestartSec = 5;
          DynamicUser = true;
          User = "peculiar-insights";
          LoadCredential = keyCredentials ++ uploadCredentials ++ tlsCredentials;
          ProtectSystem = "strict";
          ProtectHome = true;
          PrivateTmp = true;
          PrivateDevices = true;
          NoNewPrivileges = true;
          ProtectKernelTunables = true;
          ProtectKernelModules = true;
          ProtectControlGroups = true;
          RestrictAddressFamilies = [
            "AF_UNIX"
            "AF_INET"
            "AF_INET6"
          ];
          RestrictNamespaces = true;
          LockPersonality = true;
          MemoryDenyWriteExecute = true;
          SystemCallArchitectures = "native";
          SystemCallFilter = [
            "@system-service"
            "~@privileged"
          ];
        };
      };
    })
  ];
}
