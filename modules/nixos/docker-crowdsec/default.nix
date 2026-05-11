{
  config,
  lib,
  ...
}: let
  cfg = config.kuri.docker-crowdsec;
in {
  options.kuri.docker-crowdsec = {
    enable = lib.mkEnableOption "CrowdSec WAF";
    dataDir = lib.mkOption {
      type = lib.types.str;
      description = "Base data directory for CrowdSec volumes";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."services/crowdsec/env" = {};

    virtualisation.oci-containers.containers."crowdsec" = {
      image = "crowdsecurity/crowdsec:v1.7.8"; # renovate
      serviceName = "crowdsec";

      environmentFiles = [
        config.sops.secrets."services/crowdsec/env".path
      ];

      volumes = [
        "${cfg.dataDir}/data:/var/lib/crowdsec/data"
        "${cfg.dataDir}/etc:/etc/crowdsec"
        "/srv/docker/traefik/logs:/var/log/traefik:ro"
      ];

      extraOptions = lib.kuri.docker.mkHealthCheck {
        cmd = "wget -q -O /dev/null http://localhost:8080/health";
      };

      labels = {
        "traefik.enable" = "false";
        "friloux.me/health-watch" = "true";
      };

      networks = ["web"];
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir}/data 0750 0 0 -"
      "d ${cfg.dataDir}/etc 0750 0 0 -"
    ];
  };
}
