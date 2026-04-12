{ system, lib, pkgs, config, ... }:

let
  uid = 65001;
  gid = 65001;
in
{
  virtualisation.oci-containers.containers."papra" = {
    image = "ghcr.io/papra-hq/papra:latest";
    serviceName = "papra";
    user = "${toString uid}:${toString gid}";

    environmentFiles = [
      config.sops.secrets."services/papra/env".path
    ];

    volumes = [
      "/srv/docker/docs.friloux.me/data:/app/app-data"
    ];

    labels = {
      "traefik.enable" = "true";
      "traefik.http.routers.papra.rule" = "Host(`docs.friloux.me`)";
      "traefik.http.routers.papra.tls" = "true";
      "traefik.http.routers.papra.tls.certresolver" = "lets-encrypt";
      "traefik.docker.network" = "web";
      "traefik.http.services.papra.loadbalancer.server.port" = "1221";
      "com.centurylinklabs.watchtower.enable" = "true";
    };
      
    networks = [
      "web"
    ];
  };

  systemd.services."papra-secret" = {
    serviceConfig.Type = "oneshot";
    script = "systemctl restart papra.service";
  };
  
  systemd.paths."papra-secret" = {
    wantedBy = [ "multi-user.target" ];
    pathConfig.PathChanged = config.sops.secrets."services/papra/env".path;
  };

  users.groups.papra = {
    gid = gid;
  };
  users.users.papra = {
    createHome = false;
    isSystemUser = true;
    uid = uid;
    group = "papra";
    shell = "${pkgs.shadow}/bin/nologin";
  };

  systemd.tmpfiles.rules = [
    "d /srv/docker/docs.friloux.me 0750 ${toString uid} ${toString gid} -"
    "d /srv/docker/docs.friloux.me/data 0750 ${toString uid} ${toString gid} -"
    "d /srv/docker/docs.friloux.me/data/db 0750 ${toString uid} ${toString gid} -"
    "d /srv/docker/docs.friloux.me/data/documents 0750 ${toString uid} ${toString gid} -"
  ];
}
