{ system, lib, pkgs, ... }:

{
  virtualisation.oci-containers.containers."traefik" = {
    image = "traefik:v3";
    serviceName = "traefik";

    volumes = [
      "/run/docker.sock:/var/run/docker.sock"
      "/srv/docker/traefik/traefik.toml:/traefik.toml"
      "/srv/docker/traefik/traefik_dynamic.toml:/traefik_dynamic.toml"
      "/srv/docker/traefik/acme.json:/acme.json"
      "/srv/docker/traefik/access.log:/access.log"
    ];
      
    ports = [
      "80:80/tcp"
      "443:443/tcp"
    ];
    networks = [
      "web"
    ];
  };

  systemd.services."docker-network-web" = {
    path = [ pkgs.docker ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStop = "${pkgs.docker}/bin/docker network rm -f web";
    };
    script = ''
      docker network inspect web || docker network create web
    '';
    partOf = [ "docker-compose-traefik-root.target" ];
    wantedBy = [
      "docker-compose-traefik-root.target"
      "traefik.service"
    ];
  };

  systemd.targets."docker-compose-traefik-root" = {
    unitConfig = {
      Description = "One target to manage traefik";
    };
    wantedBy = [ "multi-user.target" ];
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
