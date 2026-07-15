{
  config,
  inputs,
  pkgs,
  ...
}: {
  sops.secrets."services/immich/env" = {};

  virtualisation.oci-containers.containers = {
    "immich-server" = {
      image = "altran1502/immich-server:v3.0.1"; # renovate
      serviceName = "immich-server";
      dependsOn = ["immich-postgres" "immich-redis"];

      environmentFiles = [
        config.sops.secrets."services/immich/env".path
      ];

      environment = {
        DB_HOSTNAME = "immich-postgres";
        DB_USERNAME = "immich";
        DB_DATABASE_NAME = "immich";
        REDIS_HOSTNAME = "immich-redis";
        TZ = "Europe/Paris";
      };

      volumes = [
        "/srv/docker/photos.friloux.me/upload:/usr/src/app/upload"
        "/etc/localtime:/etc/localtime:ro"
      ];

      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.immich.rule" = "Host(`photos.friloux.me`)";
        "traefik.http.routers.immich.tls" = "true";
        "traefik.http.routers.immich.tls.certresolver" = "letsencrypt";
        "traefik.docker.network" = "web";
        "traefik.http.services.immich.loadbalancer.server.port" = "2283";
        "traefik.http.routers.immich.middlewares" = "crowdsec@file,rate-limit@file,security-headers@file";
        "stc.docker/health-watch" = "true";
      };

      networks = ["immich" "web"];
    };

    "immich-postgres" = {
      # Mise à jour manuelle uniquement — suivre les release notes Immich avant tout upgrade
      image = "ghcr.io/immich-app/postgres:17-vectorchord0.5.3-pgvector0.8.1";
      serviceName = "immich-postgres";

      environmentFiles = [
        config.sops.secrets."services/immich/env".path
      ];

      environment = {
        POSTGRES_USER = "immich";
        POSTGRES_DB = "immich";
        POSTGRES_INITDB_ARGS = "--data-checksums";
      };

      extraOptions = inputs.stc.lib.docker.mkHealthCheck {
        cmd = "pg_isready -U immich -d immich";
        startPeriod = "30s";
      };

      volumes = [
        "/srv/docker/photos.friloux.me/db:/var/lib/postgresql/data"
      ];

      labels = {
        "traefik.enable" = "false";
        "stc.docker/health-watch" = "true";
      };

      networks = ["immich"];
    };

    "immich-redis" = {
      image = "redis:8-alpine"; # renovate
      serviceName = "immich-redis";

      extraOptions = inputs.stc.lib.docker.mkHealthCheck {
        cmd = "redis-cli ping";
        startPeriod = "10s";
      };

      labels = {
        "traefik.enable" = "false";
        "stc.docker/health-watch" = "true";
      };

      networks = ["immich"];
    };
  };

  systemd = {
    services."docker-immich-postgres".serviceConfig.TimeoutStartSec = "300";

    services."docker-network-immich" =
      inputs.stc.lib.docker.mkNetwork pkgs "immich"
      // {
        wantedBy = [
          "immich-server.service"
          "immich-postgres.service"
          "immich-redis.service"
        ];
      };

    tmpfiles.rules = [
      "d /srv/docker/photos.friloux.me/upload 0750 0 0 -"
      "d /srv/docker/photos.friloux.me/db 0750 immich-postgres immich-postgres -"
    ];
  };

  users.groups."immich-postgres" = {
    gid = 999;
  };
  users.users."immich-postgres" = {
    createHome = false;
    isSystemUser = true;
    uid = 999;
    group = "immich-postgres";
    shell = "${pkgs.shadow}/bin/nologin";
  };
}
