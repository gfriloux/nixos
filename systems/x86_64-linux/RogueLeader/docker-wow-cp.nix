{
  pkgs,
  config,
  inputs,
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
      image = "linuxserver/bookstack:26.09.20260929"; # renovate
      serviceName = "wow-cp-bookstack";
      dependsOn = ["wow-cp-mariadb"];
      environmentFiles = [
        config.sops.secrets."services/wow-cp/env_bookstack".path
      ];
      volumes = [
        "/srv/docker/wow-cp.friloux.me/data:/config"
      ];
      extraOptions = inputs.stc.lib.docker.mkHealthCheck {
        cmd = "curl -fs http://localhost/status | grep -q '\"database\":true'";
        startPeriod = "300s";
      };
      # Publié par la passerelle pangolin (wow-cp.friloux.me), via newt sur
      # le réseau web : plus de route sur le traefik local, donc plus de
      # rate-limit strict sur /login. BookStack bloque lui-même après 5
      # essais par minute (compte + IP) ; APP_PROXIES=* dans son env lui fait
      # lire la vraie IP, sûr car seul newt le joint (aucun port publié).
      labels."stc.docker/health-watch" = "true";
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
      extraOptions = inputs.stc.lib.docker.mkHealthCheck {
        cmd = "mysqladmin ping -h localhost --silent";
      };
      labels = {
        "traefik.enable" = "false";
        "stc.docker/health-watch" = "true";
      };
      networks = [
        "wow-cp"
      ];
    };
    "wow-cp-mysqldump" = {
      image = "fradelg/mysql-cron-backup:1.15.0"; # renovate
      serviceName = "wow-cp-mysqldump";
      dependsOn = ["wow-cp-mariadb"];
      environmentFiles = [
        config.sops.secrets."services/wow-cp/env_mysqldump".path
      ];
      # The image's MariaDB client requires TLS by default, which
      # linuxserver/mariadb 10.5 does not offer: every dump since mid-July
      # failed with "SSL is required, but the server does not support it"
      # while the container stayed healthy. Plain TCP stays on the private
      # wow-cp network.
      environment.MYSQL_SSL_OPTS = "--skip-ssl";
      volumes = [
        "/srv/docker/wow-cp.friloux.me/dumps:/backup"
      ];
      labels = {
        "traefik.enable" = "false";
        # fradelg/mysql-cron-backup declares its own HEALTHCHECK
        "stc.docker/health-cmd-in-image" = "true";
        "stc.docker/health-watch" = "true";
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
    services."docker-network-wow-cp" =
      inputs.stc.lib.docker.mkNetwork pkgs "wow-cp"
      // {
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
