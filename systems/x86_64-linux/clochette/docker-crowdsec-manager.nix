{pkgs, ...}: let
  # clochette's Tailscale address. Changes if the node is re-enrolled
  # (reinstall): update it here, see docs operations/tailscale.md.
  tailscaleIp = "100.124.91.99";
in {
  virtualisation.oci-containers.containers."crowdsec-manager" = {
    image = "hhftechnology/crowdsec-manager:2.4.1"; # renovate
    serviceName = "crowdsec-manager";

    environment = {
      PORT = "8080";
      ENVIRONMENT = "production";
      DOCKER_HOST = "unix:///var/run/docker.sock";
      CONFIG_DIR = "/app/config";
      DATABASE_PATH = "/app/data/settings.db";
      INCLUDE_CROWDSEC = "true";
      CROWDSEC_METRICS_URL = "http://crowdsec:6060/metrics";
      TRAEFIK_CONTAINER_NAME = "traefik";
      TRAEFIK_DYNAMIC_CONFIG = "/etc/traefik/traefik_dynamic.yml";
      TRAEFIK_STATIC_CONFIG = "/etc/traefik/traefik.yml";
    };

    # Accepted risk: raw socket, not the socket-proxy. crowdsec-manager execs
    # into containers (incl. a web shell), copies files in, restarts them and
    # recreates them (pull + create) for updates. The proxy would need
    # CONTAINERS+EXEC+IMAGES+POST, which is root on the host anyway. The UI has
    # no authentication, so the real boundary is the Tailscale-only port below:
    # never publish it anywhere else.
    volumes = [
      "/run/docker.sock:/var/run/docker.sock"
      "/srv/docker/crowdsec-manager/data:/app/data"
      "/srv/docker/crowdsec-manager/config:/app/config"
    ];

    # Tailscale only: a bare "3000:8080" binds 0.0.0.0, and Docker's DNAT rules
    # run before networking.firewall, so this unauthenticated admin UI was
    # reachable from the Internet.
    ports = ["${tailscaleIp}:3000:8080/tcp"];

    labels = {
      "traefik.enable" = "false";
    };

    networks = ["web"];
  };

  systemd = {
    services."crowdsec-manager" = {
      after = ["crowdsec.service" "tailscaled.service"];
      requires = ["crowdsec.service"];
      wants = ["tailscaled.service"];
      # Docker cannot publish on an address that does not exist yet. At boot
      # tailscaled is "started" before tailscale0 holds its IP; a failed bind
      # restarts within 100ms and hits systemd's start limit (5 in 10s), leaving
      # the UI down until someone notices.
      preStart = ''
        tries=0
        until ${pkgs.iproute2}/bin/ip -4 addr show dev tailscale0 | grep -qF ${tailscaleIp}; do
          tries=$((tries + 1))
          if [ "$tries" -ge 60 ]; then
            echo "${tailscaleIp} not on tailscale0 after 60s" >&2
            exit 1
          fi
          sleep 1
        done
      '';
    };
    tmpfiles.rules = [
      "d /srv/docker/crowdsec-manager 0750 0 0 -"
      "d /srv/docker/crowdsec-manager/data 0750 0 0 -"
      "d /srv/docker/crowdsec-manager/config 0750 0 0 -"
    ];
  };
}
