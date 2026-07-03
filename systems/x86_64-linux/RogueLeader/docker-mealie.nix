{lib, ...}: {
  virtualisation.oci-containers.containers."mealie" = {
    image = "hkotel/mealie:v3.20.1"; # renovate
    serviceName = "mealie";

    environment = {
      DB_ENGINE = "sqlite";
      WEB_CONCURRENCY = "2";
      DEFAULT_EMAIL = "guillaume@friloux.me";
      BASE_URL = "https://cuisine.home.friloux.me";
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
      ++ lib.kuri.docker.mkHealthCheck {
        cmd = "curl -f http://localhost:9000/api/app/about";
      };

    labels = {
      "traefik.enable" = "true";
      "traefik.http.routers.mealie.rule" = "Host(`cuisine.home.friloux.me`)";
      "traefik.http.routers.mealie.tls" = "true";
      "traefik.http.routers.mealie.tls.certresolver" = "lets-encrypt";
      "traefik.docker.network" = "web";
      "traefik.http.services.mealie.loadbalancer.server.port" = "9000";
      "traefik.http.routers.mealie.middlewares" = "crowdsec@file,rate-limit@file,security-headers@file";
      "friloux.me/health-watch" = "true";
    };

    networks = [
      "web"
    ];
  };

  systemd.tmpfiles.rules = [
    "d /srv/docker/cuisine.home.friloux.me/data 0750 0 0 -"
  ];
}
