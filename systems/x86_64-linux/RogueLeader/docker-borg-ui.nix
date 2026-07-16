{
  inputs,
  pkgs,
  ...
}: {
  virtualisation.oci-containers.containers = {
    "borg-ui" = {
      image = "ainullcode/borg-ui:2.2.6"; # renovate
      serviceName = "borg-ui";
      dependsOn = ["borg-redis"];

      environment = {
        PORT = "8081";
        PUID = "1001";
        PGID = "1001";
        TZ = "Europe/Paris";
        REDIS_HOST = "borg-redis";
        REDIS_PORT = "6379";
        REDIS_DB = "0";
      };

      volumes = [
        "/srv/docker/borg-ui.friloux.me/data:/data"
        "/srv/docker/borg-ui.friloux.me/cache:/home/borg/.cache/borg"
        "/etc/localtime:/etc/localtime:ro"
      ];

      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.borg-ui.rule" = "Host(`borg-ui.friloux.me`)";
        "traefik.http.routers.borg-ui.tls" = "true";
        "traefik.http.routers.borg-ui.tls.certresolver" = "letsencrypt";
        "traefik.docker.network" = "web";
        "traefik.http.services.borg-ui.loadbalancer.server.port" = "8081";
        "traefik.http.routers.borg-ui.middlewares" = "crowdsec@file,rate-limit@file,security-headers@file";
        "stc.docker/health-watch" = "true";
      };

      networks = ["borg-ui" "web"];
    };

    "borg-redis" = {
      image = "redis:8-alpine"; # renovate
      serviceName = "borg-redis";

      extraOptions = inputs.stc.lib.docker.mkHealthCheck {
        cmd = "redis-cli ping";
        startPeriod = "10s";
      };

      labels = {
        "traefik.enable" = "false";
        "stc.docker/health-watch" = "true";
      };

      networks = ["borg-ui"];
    };
  };

  users.groups.borg-ui = {
    gid = 1001;
  };
  users.users.borg-ui = {
    createHome = false;
    isSystemUser = true;
    uid = 1001;
    group = "borg-ui";
    shell = "${pkgs.shadow}/bin/nologin";
  };

  systemd = {
    services."docker-network-borg-ui" =
      inputs.stc.lib.docker.mkNetwork pkgs "borg-ui"
      // {
        wantedBy = [
          "borg-ui.service"
          "borg-redis.service"
        ];
      };

    tmpfiles.rules = [
      "d /srv/docker/borg-ui.friloux.me/data 0750 borg-ui borg-ui -"
      "d /srv/docker/borg-ui.friloux.me/cache 0750 borg-ui borg-ui -"
    ];
  };
}
