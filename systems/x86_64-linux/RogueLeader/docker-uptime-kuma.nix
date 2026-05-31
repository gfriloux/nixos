{lib, ...}: {
  virtualisation.oci-containers.containers."uptime-kuma" = {
    image = "louislam/uptime-kuma:2.4.0"; # renovate
    serviceName = "uptime-kuma";

    volumes = [
      "/srv/docker/status.friloux.me/data:/app/data"
    ];

    extraOptions = lib.kuri.docker.mkHealthCheck {
      cmd = "curl -f http://localhost:3001/api/entry-page";
    };

    labels = {
      "traefik.enable" = "true";
      "traefik.http.routers.uptime-kuma.rule" = "Host(`status.friloux.me`)";
      "traefik.http.routers.uptime-kuma.tls" = "true";
      "traefik.http.routers.uptime-kuma.tls.certresolver" = "lets-encrypt";
      "traefik.docker.network" = "web";
      "traefik.http.services.uptime-kuma.loadbalancer.server.port" = "3001";
      "traefik.http.routers.uptime-kuma.middlewares" = "crowdsec@file,rate-limit@file,security-headers@file";
      "friloux.me/health-watch" = "true";
    };

    networks = [
      "web"
    ];
  };

  systemd.tmpfiles.rules = [
    "d /srv/docker/status.friloux.me/data 0750 0 0 -"
  ];
}
