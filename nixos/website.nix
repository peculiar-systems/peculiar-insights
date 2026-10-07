{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    ;

  cfg = config.services.peculiar-insights-website;
in
{
  options.services.peculiar-insights-website = {
    enable = mkEnableOption "the Peculiar Insights website";

    domain = mkOption {
      type = types.str;
      default = "insights.peculiar.systems";
      description = "The virtual host serving the site";
    };

    package = mkOption {
      type = types.package;
      description = "The built static site";
    };

    forceSSL = mkOption {
      type = types.bool;
      default = true;
      description = "Redirect plain HTTP to HTTPS";
    };

    enableACME = mkOption {
      type = types.bool;
      default = true;
      description = "Obtain the certificate through ACME";
    };
  };

  config = mkIf cfg.enable {
    services.nginx = {
      enable = true;
      virtualHosts.${cfg.domain} = {
        inherit (cfg) forceSSL enableACME;
        root = cfg.package;
        locations."/" = {
          tryFiles = "$uri $uri/ /404/index.html";
        };
        extraConfig = ''
          error_page 404 /404/index.html;
        '';
      };
    };
  };
}
