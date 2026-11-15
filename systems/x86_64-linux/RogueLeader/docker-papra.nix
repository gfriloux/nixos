{
  pkgs,
  config,
  inputs,
  ...
}: let
  # The rootless image ships neither curl nor wget: bash's /dev/tcp does the GET.
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
    image = "ghcr.io/papra-hq/papra:26.7.1-rootless@sha256:d1f596a35332ad04d8a69d88a5e19bc82acd47f2bc2fe687dd2145b1ef5a8b19"; # renovate
    serviceName = "papra";
    user = "${toString config.users.users.papra.uid}:${toString config.users.groups.papra.gid}";

    environmentFiles = [
      config.sops.secrets."services/papra/env".path
    ];

    volumes = [
      "/srv/docker/docs.friloux.me/data:/app/app-data"
    ];

    # Publié par la passerelle pangolin (docs.friloux.me), via newt sur le
    # réseau web : plus de route sur le traefik local. La connexion reste
    # limitée par better-auth (3 essais par 10 s sur /api/auth/sign-in), qui
    # lit la vraie IP dans X-Forwarded-For, réécrit par le traefik de skitarii.
    labels."stc.docker/health-watch" = "true";

    extraOptions = inputs.stc.lib.docker.mkHealthCheck {
      cmd = healthCmd;
    };

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
