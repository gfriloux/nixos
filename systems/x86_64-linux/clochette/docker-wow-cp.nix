{
  pkgs,
  config,
  ...
}: {
  sops = {
    secrets = {
      "services/wow-cp/env_bookstack" = {};
      "services/wow-cp/env_mariadb" = {};
      "services/wow-cp/env_mysqldump" = {};
    };
  };

  virtualisation.oci-containers.containers = {
    "wow-cp-bookstack" = {
      image = "linuxserver/bookstack:26.03.20260315"; # renovate
      serviceName = "wow-cp-bookstack";
      dependsOn = ["wow-cp-mariadb"];
      environmentFiles = [
        config.sops.secrets."services/wow-cp/env_bookstack".path
      ];
      volumes = [
        "/srv/docker/wow-cp.friloux.me/data:/config"
      ];
      extraOptions = [
        "--health-cmd=curl -fs http://localhost/status | grep -q '\"database\":true'"
        "--health-interval=30s"
        "--health-timeout=10s"
        "--health-start-period=60s"
        "--health-retries=3"
      ];
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.wowcp.rule" = "Host(`wow-cp.friloux.me`)";
        "traefik.http.routers.wowcp.tls" = "true";
        "traefik.http.routers.wowcp.tls.certresolver" = "lets-encrypt";
        "traefik.docker.network" = "web";
        "traefik.http.routers.wowcp.middlewares" = "crowdsec@file,rate-limit@file,security-headers@file";
        "traefik.http.routers.wowcp-login.rule" = "Host(`wow-cp.friloux.me`) && Path(`/login`)";
        "traefik.http.routers.wowcp-login.middlewares" = "crowdsec@file,rate-limit-strict@file,security-headers@file";
        "friloux.me/health-watch" = "true";
      };
      networks = [
        "wow-cp"
        "web"
      ];
    };
    "wow-cp-mariadb" = {
      image = "linuxserver/mariadb:10.5.15";
      serviceName = "wow-cp-mariadb";
      environmentFiles = [
        config.sops.secrets."services/wow-cp/env_mariadb".path
      ];
      volumes = [
        "/srv/docker/wow-cp.friloux.me/db:/config"
      ];
      extraOptions = [
        "--health-cmd=mysqladmin ping -h localhost --silent"
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
        "wow-cp"
      ];
    };
    "wow-cp-mysqldump" = {
      image = "fradelg/mysql-cron-backup:1.14.2"; # renovate
      serviceName = "wow-cp-mysqldump";
      dependsOn = ["wow-cp-mariadb"];
      environmentFiles = [
        config.sops.secrets."services/wow-cp/env_mysqldump".path
      ];
      volumes = [
        "/srv/docker/wow-cp.friloux.me/dumps:/backup"
      ];
      labels = {
        "traefik.enable" = "false";
        "friloux.me/health-watch" = "true";
      };
      networks = [
        "wow-cp"
      ];
    };
  };

  users.groups.wow-cp = {
    gid = 65002;
  };
  users.users.wow-cp = {
    createHome = false;
    isSystemUser = true;
    uid = 65002;
    group = "wow-cp";
    shell = "${pkgs.shadow}/bin/nologin";
  };

  systemd = {
    services."docker-network-wow-cp" = {
      path = [pkgs.docker];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStop = "${pkgs.docker}/bin/docker network rm -f wow-cp";
      };
      script = ''
        docker network inspect wow-cp || docker network create wow-cp
      '';
      wantedBy = [
        "wow-cp-bookstack.service"
        "wow-cp-mariadb.service"
        "wow-cp-mysqldump.service"
      ];
    };

    tmpfiles.rules = [
      "d /srv/docker/wow-cp.friloux.me 0750 wow-cp wow-cp -"
      "d /srv/docker/wow-cp.friloux.me/data 0750 wow-cp wow-cp -"
      "d /srv/docker/wow-cp.friloux.me/db 0750 wow-cp wow-cp -"
      "d /srv/docker/wow-cp.friloux.me/dumps 0750 wow-cp wow-cp -"
    ];
  };
}
