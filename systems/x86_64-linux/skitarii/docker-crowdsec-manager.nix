_: {
  virtualisation.oci-containers.containers."crowdsec-manager" = {
    image = "hhftechnology/crowdsec-manager:2.4.1"; # renovate
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
      # Fichiers du store, en lecture seule : l'édition de la config traefik
      # depuis l'UI ne marche pas ici, elle passe par docker-pangolin.nix.
      TRAEFIK_DYNAMIC_CONFIG = "/etc/traefik/dynamic_config.yml";
      TRAEFIK_STATIC_CONFIG = "/etc/traefik/traefik_config.yml";
    };

    # Risque accepté, en connaissance de cause : socket brut, donc root sur
    # l'hôte (exec, web shell, recréation de conteneurs). Contrairement à
    # clochette, l'UI est publiée, via une ressource pangolin
    # (crowdsec.friloux.me) derrière le SSO pangolin avec 2FA. Aucun port
    # publié ici : la seule entrée est traefik, par le réseau pangolin.
    volumes = [
      "/run/docker.sock:/var/run/docker.sock"
      "/srv/docker/crowdsec-manager/data:/app/data"
      "/srv/docker/crowdsec-manager/config:/app/config"
    ];

    networks = ["pangolin"];
  };

  systemd = {
    services."crowdsec-manager" = {
      after = ["crowdsec.service" "docker-network-pangolin.service"];
      requires = ["crowdsec.service" "docker-network-pangolin.service"];
    };
    tmpfiles.rules = [
      "d /srv/docker/crowdsec-manager 0750 0 0 -"
      "d /srv/docker/crowdsec-manager/data 0750 0 0 -"
      "d /srv/docker/crowdsec-manager/config 0750 0 0 -"
    ];
  };
}
