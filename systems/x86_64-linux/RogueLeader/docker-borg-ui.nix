{
  inputs,
  pkgs,
  ...
}: {
  virtualisation.oci-containers.containers = {
    "borg-ui" = {
      image = "ainullcode/borg-ui:2.4.10@sha256:c5e56440bf4150defe6c9eeaa2c6cff8322d285490a2b6e1dc3c127c3f31926b"; # renovate
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

      # Publié par la passerelle pangolin (borg-ui.friloux.me), via newt sur
      # le réseau web : plus de route sur le traefik local. Pas de SSO
      # pangolin, borg-ui a sa propre authentification.
      labels = {
        # ainullcode/borg-ui declares its own HEALTHCHECK (curl on $PORT)
        "stc.docker/health-cmd-in-image" = "true";
        "stc.docker/health-watch" = "true";
      };

      networks = ["borg-ui" "web"];
    };

    "borg-redis" = {
      image = "redis:8-alpine@sha256:7958cfbb9d152f87dadfbc89f1b0b15938f0b81ff8982feb327476f4911935c3"; # renovate
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
