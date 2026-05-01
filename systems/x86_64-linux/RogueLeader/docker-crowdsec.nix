{config, ...}: {
  sops.secrets."services/crowdsec/env" = {};

  virtualisation.oci-containers.containers."crowdsec" = {
    image = "crowdsecurity/crowdsec:v1.7.7"; # renovate
    serviceName = "crowdsec";

    environmentFiles = [
      config.sops.secrets."services/crowdsec/env".path
    ];

    volumes = [
      "/srv/docker/crowdsec.rogueleader.home/data:/var/lib/crowdsec/data"
      "/srv/docker/crowdsec.rogueleader.home/etc:/etc/crowdsec"
      "/srv/docker/traefik/logs:/var/log/traefik:ro"
    ];

    extraOptions = [
      "--health-cmd=wget -q -O /dev/null http://localhost:8080/health"
      "--health-interval=30s"
      "--health-timeout=10s"
      "--health-start-period=30s"
      "--health-retries=3"
    ];

    labels = {
      "traefik.enable" = "false";
      "friloux.me/health-watch" = "true";
    };

    networks = [
      "web"
    ];
  };

  systemd.tmpfiles.rules = [
    "d /srv/docker/crowdsec.rogueleader.home/data 0750 0 0 -"
    "d /srv/docker/crowdsec.rogueleader.home/etc 0750 0 0 -"
  ];
}
