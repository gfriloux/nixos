{
  pkgs,
  config,
  ...
}: let
  uid = 65002;
  gid = 65002;
in {
  virtualisation.oci-containers.containers = {
    "wow-cp-bookstack" = {
      image = "linuxserver/bookstack:26.03.3"; # renovate: datasource=docker depName=fradelg/mysql-cron-backup
      serviceName = "wow-cp-bookstack";
      dependsOn = ["wow-cp-mariadb"];
      environmentFiles = [
        config.sops.secrets."services/wow-cp/env_bookstack".path
      ];
      volumes = [
        "/srv/docker/wow-cp.friloux.me/data:/config"
      ];
      labels = {
        "traefik.http.routers.wowcp.rule" = "Host(`wow-cp.friloux.me`)";
        "traefik.http.routers.wowcp.tls" = "true";
        "traefik.http.routers.wowcp.tls.certresolver" = "lets-encrypt";
        "traefik.docker.network" = "web";
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
      labels = {
        "traefik.enable" = "false";
      };
      networks = [
        "wow-cp"
      ];
    };
    "wow-cp-mysqldump" = {
      image = "fradelg/mysql-cron-backup:1.14.2"; # renovate: datasource=docker depName=fradelg/mysql-cron-backup
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
      };
      networks = [
        "wow-cp"
      ];
    };
  };

  systemd.services."docker-network-wow-cp" = {
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

  users.groups.wow-cp = {
    inherit gid;
  };
  users.users.wow-cp = {
    createHome = false;
    isSystemUser = true;
    inherit uid;
    group = "wow-cp";
    shell = "${pkgs.shadow}/bin/nologin";
  };

  systemd.tmpfiles.rules = [
    "d /srv/docker/wow-cp.friloux.me 0750 ${toString uid} ${toString gid} -"
    "d /srv/docker/wow-cp.friloux.me/data 0750 ${toString uid} ${toString gid} -"
    "d /srv/docker/wow-cp.friloux.me/db 0750 ${toString uid} ${toString gid} -"
    "d /srv/docker/wow-cp.friloux.me/dumps 0750 ${toString uid} ${toString gid} -"
  ];
}
