{inputs, ...}: {
  virtualisation.oci-containers.containers."mealie" = {
    image = "hkotel/mealie:v3.29.0"; # renovate
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
      "/srv/docker/cuisine.home.friloux.me/data:/app/data"
    ];

    extraOptions =
      [
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
