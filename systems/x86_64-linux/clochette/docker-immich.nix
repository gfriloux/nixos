{
  config,
  inputs,
  pkgs,
  ...
}: {
  sops.secrets."services/immich/env" = {};

  virtualisation.oci-containers.containers = {
    "immich-server" = {
      image = "altran1502/immich-server:v3.3.5"; # renovate
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

      # L'image ne déclare aucun HEALTHCHECK (vérifié avec `skopeo inspect
      # --config`), donc sans ça le health-watch ne surveille rien. curl est
      # présent dans l'image (/usr/bin/curl) et /api/server/ping ne demande
      # pas d'authentification.
      extraOptions = inputs.stc.lib.docker.mkHealthCheck {
        cmd = "curl -f http://localhost:2283/api/server/ping";
        startPeriod = "60s";
      };

      # Publié par la passerelle pangolin (photos.friloux.me), via newt sur le
      # réseau web : plus de route sur le traefik local. immich ne limite pas
      # les essais de connexion ; le crowdsec de skitarii bannit après une
      # rafale de POST en 401 (LePresidente/http-generic-401-bf).
      labels."stc.docker/health-watch" = "true";

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
