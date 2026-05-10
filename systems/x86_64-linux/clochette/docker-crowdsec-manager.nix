_: {
  virtualisation.oci-containers.containers."crowdsec-manager" = {
    image = "hhftechnology/crowdsec-manager:2.4.0"; # renovate
    serviceName = "crowdsec-manager";

    environment = {
      PORT = "8080";
      ENVIRONMENT = "production";
      DOCKER_HOST = "unix:///var/run/docker.sock";
      CONFIG_DIR = "/app/config";
      DATABASE_PATH = "/app/data/settings.db";
      INCLUDE_CROWDSEC = "true";
      CROWDSEC_METRICS_URL = "http://crowdsec:6060/metrics";
      TRAEFIK_CONTAINER_NAME = "traefik";
      TRAEFIK_DYNAMIC_CONFIG = "/etc/traefik/traefik_dynamic.yml";
      TRAEFIK_STATIC_CONFIG = "/etc/traefik/traefik.yml";
    };

    volumes = [
      "/run/docker.sock:/var/run/docker.sock"
      "/srv/docker/crowdsec-manager/data:/app/data"
      "/srv/docker/crowdsec-manager/config:/app/config"
    ];

    ports = ["3000:8080/tcp"];

    labels = {
      "traefik.enable" = "false";
    };

    networks = ["web"];
  };

  systemd = {
    services."docker-crowdsec-manager" = {
      after = ["docker-crowdsec.service"];
      requires = ["docker-crowdsec.service"];
    };
    tmpfiles.rules = [
      "d /srv/docker/crowdsec-manager 0750 0 0 -"
      "d /srv/docker/crowdsec-manager/data 0750 0 0 -"
      "d /srv/docker/crowdsec-manager/config 0750 0 0 -"
    ];
  };
}
