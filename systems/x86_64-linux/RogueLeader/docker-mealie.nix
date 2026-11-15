{inputs, ...}: {
  virtualisation.oci-containers.containers."mealie" = {
    image = "hkotel/mealie:v3.31.0@sha256:97e21ac96e9a8d1ee15aaf558ba3f14998936b9d6f334e40ebb4c6c2127dc12f"; # renovate
    serviceName = "mealie";

    environment = {
      DB_ENGINE = "sqlite";
      WEB_CONCURRENCY = "2";
      DEFAULT_EMAIL = "guillaume@friloux.me";
      BASE_URL = "https://cuisine.friloux.me";
      RECIPE_PUBLIC = "true";
      RECIPE_SHOW_NUTRITION = "true";
      RECIPE_SHOW_ASSETS = "true";
      RECIPE_LANDSCAPE_VIEW = "true";
      RECIPE_DISABLE_COMMENTS = "false";
      RECIPE_DISABLE_AMOUNT = "false";
      TZ = "Europe/Paris";
    };

    volumes = [
      # Old hostname: every service here lived under home.friloux.me before
      # the pangolin gateway. Kept, the data is there and backup.nix names it.
      "/srv/docker/cuisine.home.friloux.me/data:/app/data"
    ];

    extraOptions =
      [
        # Public resolvers on purpose, instead of the ones Docker inherits
        # from the host.
        "--dns=8.8.8.8"
        "--dns=1.1.1.1"
      ]
      ++ inputs.stc.lib.docker.mkHealthCheck {
        cmd = "curl -f http://localhost:9000/api/app/about";
      };

    # Publié par la passerelle pangolin (cuisine.friloux.me), via newt sur le
    # réseau web : plus de route sur le traefik local.
    labels."stc.docker/health-watch" = "true";

    networks = [
      "web"
    ];
  };

  systemd.tmpfiles.rules = [
    "d /srv/docker/cuisine.home.friloux.me/data 0750 0 0 -"
  ];
}
