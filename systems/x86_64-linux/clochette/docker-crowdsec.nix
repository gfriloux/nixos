{config, ...}: {
  sops = {
    secrets = {
      "services/crowdsec/env" = {};
    };
  };

  virtualisation.oci-containers.containers."crowdsec" = {
    image = "crowdsecurity/crowdsec:v1.7.7"; # renovate
    serviceName = "crowdsec";

    environmentFiles = [
      config.sops.secrets."services/crowdsec/env".path
    ];

    volumes = [
      "/srv/docker/crowdsec.clochette.friloux.me/data:/var/lib/crowdsec/data"
      "/srv/docker/crowdsec.clochette.friloux.me/etc:/etc/crowdsec"
      "/srv/docker/traefik/logs:/var/log/traefik:ro"
    ];

    labels = {
      "traefik.enable" = "false";
    };

    networks = [
      "web"
    ];
  };

  systemd.tmpfiles.rules = [
    "d /srv/docker/crowdsec.clochette.friloux.me/data 0750 0 0 -"
    "d /srv/docker/crowdsec.clochette.friloux.me/etc 0750 0 0 -"
  ];
}
