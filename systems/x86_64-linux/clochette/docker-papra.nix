{
  pkgs,
  config,
  ...
}: let
  healthCmd = "bash -c 'exec 3<>/dev/tcp/127.0.0.1/1221 && printf \"GET /api/health HTTP/1.0\\r\\n\\r\\n\" >&3 && cat <&3 | grep -q isEverythingOk'";
in {
  sops = {
    secrets = {
      "services/papra/env" = {
        owner = "papra";
        group = "papra";
      };
    };
  };

  virtualisation.oci-containers.containers."papra" = {
    image = "ghcr.io/papra-hq/papra:26.4.0-rootless"; # renovate
    serviceName = "papra";
    user = "${toString config.users.users.papra.uid}:${toString config.users.groups.papra.gid}";

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
      "traefik.http.routers.papra.middlewares" = "crowdsec@file,rate-limit@file,security-headers@file";
      "traefik.http.routers.papra-login.rule" = "Host(`docs.friloux.me`) && Path(`/login`)";
      "traefik.http.routers.papra-login.middlewares" = "crowdsec@file,rate-limit-strict@file,security-headers@file";
    };

    extraOptions = [
      "--health-cmd=${healthCmd}"
      "--health-interval=30s"
      "--health-timeout=10s"
      "--health-start-period=30s"
      "--health-retries=3"
    ];

    networks = [
      "web"
    ];
  };

  users.groups.papra = {
    gid = 65001;
  };
  users.users.papra = {
    createHome = false;
    isSystemUser = true;
    uid = 65001;
    group = "papra";
    shell = "${pkgs.shadow}/bin/nologin";
  };

  systemd.tmpfiles.rules = [
    "d /srv/docker/docs.friloux.me 0750 papra papra -"
    "d /srv/docker/docs.friloux.me/data 0750 papra papra -"
    "d /srv/docker/docs.friloux.me/data/db 0750 papra papra -"
    "d /srv/docker/docs.friloux.me/data/documents 0750 papra papra -"
  ];
}
