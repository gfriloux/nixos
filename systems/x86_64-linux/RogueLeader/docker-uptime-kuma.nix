{inputs, ...}: {
  virtualisation.oci-containers.containers."uptime-kuma" = {
    image = "louislam/uptime-kuma:2.5.12@sha256:8e4b6bef96417ec98a35dc103c99cc64fc229a01e584e56d95d9004d2003c02a"; # renovate
    serviceName = "uptime-kuma";

    volumes = [
      "/srv/docker/status.friloux.me/data:/app/data"
    ];

    extraOptions = inputs.stc.lib.docker.mkHealthCheck {
      cmd = "curl -f http://localhost:3001/api/entry-page";
    };

    # Publié par la passerelle pangolin (status.friloux.me), via newt sur le
    # réseau web : plus de route sur le traefik local. Si skitarii tombe, la
    # page publique tombe aussi, mais uptime-kuma tourne ici et continue
    # d'alerter par ntfy.
    labels."stc.docker/health-watch" = "true";

    networks = [
      "web"
    ];
  };

  systemd.tmpfiles.rules = [
    "d /srv/docker/status.friloux.me/data 0750 0 0 -"
  ];
}
