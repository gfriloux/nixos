{pkgs, ...}: {
  virtualisation.oci-containers.containers."traefik" = {
    image = "traefik:v3.6.13"; # renovate
    serviceName = "traefik";

    volumes = [
      "/run/docker.sock:/var/run/docker.sock"
      "/srv/docker/traefik/traefik.toml:/traefik.toml"
      "/srv/docker/traefik/traefik_dynamic.toml:/traefik_dynamic.toml"
      "/srv/docker/traefik/acme.json:/acme.json"
      "/srv/docker/traefik/logs:/logs"
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
          "docker-compose-traefik-root.target"
          "traefik.service"
        ];
      };
    };

    targets."docker-compose-traefik-root" = {
      unitConfig = {
        Description = "One target to manage traefik";
      };
      wantedBy = ["multi-user.target"];
    };
  };

  networking.firewall.allowedTCPPorts = [80 443];

  systemd.tmpfiles.rules = [
    "d /srv/docker/traefik/logs 0750 0 0 -"
  ];
}
