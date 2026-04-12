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
      
    networks = [
      "web"
    ];
  };

  systemd.targets."docker-compose-papra-root" = {
    unitConfig = {
      Description = "One target to manage papra";
    };
    wantedBy = [ "multi-user.target" ];
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
    "d /srv/docker/papra 0750 ${toString uid} ${toString gid} -"
    "d /srv/docker/papra/data 0750 ${toString uid} ${toString gid} -"
  ];
}
