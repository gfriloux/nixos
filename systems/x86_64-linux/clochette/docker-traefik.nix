{pkgs, ...}: let
  traefikConfig = pkgs.writeText "traefik.yml" ''
    entryPoints:
      web:
        address: ":80"
        http:
          redirections:
            entryPoint:
              to: websecure
              scheme: https

      websecure:
        address: ":443"

      traefik:
        address: "127.0.0.1:8080"

    api:
      dashboard: true

    ping:
      entryPoint: traefik

    accessLog:
      filePath: "/logs/traefik.log"
      format: json
      fields:
        headers:
          defaultMode: drop
          names:
            User-Agent: keep
            X-Real-Ip: keep
            X-Forwarded-For: keep
            X-Forwarded-Proto: keep

    certificatesResolvers:
      lets-encrypt:
        acme:
          email: "guillaume+letsencrypt@friloux.me"
          storage: "acme.json"
          tlsChallenge: {}

    providers:
      docker:
        watch: true
        network: web
      file:
        filename: "/etc/traefik/traefik_dynamic.yml"

    experimental:
      plugins:
        bouncer:
          moduleName: "github.com/maxlerebourg/crowdsec-bouncer-traefik-plugin"
          version: "v1.5.1"
  '';
in {
  sops = {
    secrets = {
      "services/traefik/conf/traefik_dynamic.yml" = {
        owner = "root";
        group = "root";
        mode = "0400";
        path = "/srv/docker/traefik/conf/traefik_dynamic.yml";
      };
    };
  };

  virtualisation.oci-containers.containers."traefik" = {
    image = "traefik:v3.6.13"; # renovate
    serviceName = "traefik";

    volumes = [
      "/run/docker.sock:/var/run/docker.sock"
      "/srv/docker/traefik/conf/traefik.yml:/etc/traefik/traefik.yml"
      "/srv/docker/traefik/conf/traefik_dynamic.yml:/etc/traefik/traefik_dynamic.yml"
      "/srv/docker/traefik/acme.json:/acme.json"
      "/srv/docker/traefik/logs:/logs"
    ];

    extraOptions = [
      "--health-cmd=traefik healthcheck"
      "--health-interval=30s"
      "--health-timeout=10s"
      "--health-start-period=10s"
      "--health-retries=3"
    ];

    ports = [
      "80:80/tcp"
      "443:443/tcp"
    ];
    networks = [
      "web"
    ];
  };

  systemd = {
    services = {
      "traefik" = {
        after = ["crowdsec.service"];
        requires = ["crowdsec.service"];
      };

      "docker-network-web" = {
        path = [pkgs.docker];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStop = "${pkgs.docker}/bin/docker network rm -f web";
        };
        script = ''
          docker network inspect web || docker network create web
        '';
        partOf = ["docker-compose-traefik-root.target"];
        wantedBy = [
          "traefik.service"
        ];
      };
    };
  };

  services.logrotate.settings.traefik = {
    files = "/srv/docker/traefik/logs/traefik.log";
    frequency = "daily";
    rotate = 14;
    compress = true;
    delaycompress = true;
    missingok = true;
    notifempty = true;
    copytruncate = true;
  };

  networking.firewall.allowedTCPPorts = [80 443];

  systemd.tmpfiles.rules = [
    "d /srv/docker/traefik/logs 0750 0 0 -"
    "d /srv/docker/traefik/conf 0750 0 0 -"
    "d /srv/docker/traefik/acme.json 0600 0 0 -"
    "L+ /srv/docker/traefik/conf/traefik.yml - - - - ${traefikConfig}"
  ];
}
