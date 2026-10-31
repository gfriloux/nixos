{
  config,
  inputs,
  pkgs,
  ...
}: let
  dataDir = "/srv/docker/pangolin.friloux.me";
  yaml = pkgs.formats.yaml {};

  crowdsecAcquis = yaml.generate "traefik.yaml" {
    filenames = ["/var/log/traefik/access.log"];
    labels.type = "traefik";
  };

  # AppSec : le bouncer envoie chaque requête à crowdsec avant de la laisser
  # passer, qui la juge sur les règles des collections appsec-* (default.nix).
  # Sur le réseau pangolin seulement, aucun port publié.
  crowdsecAppsecAcquis = yaml.generate "appsec.yaml" {
    source = "appsec";
    listen_addr = "0.0.0.0:7422";
    appsec_config = "crowdsecurity/appsec-default";
    labels.type = "appsec";
  };

  # Calqué sur le compose officiel (fosrl/pangolin, install/config/traefik/).
  # Différences voulues : pas de dashboard traefik exposé, logs sur stdout.
  traefikConfig = yaml.generate "traefik_config.yml" {
    providers = {
      http = {
        endpoint = "http://pangolin:3001/api/v1/traefik-config";
        pollInterval = "5s";
      };
      file.filename = "/etc/traefik/dynamic_config.yml";
    };
    experimental.plugins = {
      badger = {
        moduleName = "github.com/fosrl/badger";
        # Pas v1.8.0 : elle échoue au contrôle d'intégrité du registre de
        # plugins traefik, qui désactive alors tous les plugins (note de
        # release badger, traefik/traefik#14115).
        version = "v1.7.0";
      };
      bouncer = {
        moduleName = "github.com/maxlerebourg/crowdsec-bouncer-traefik-plugin";
        version = "v1.5.1";
      };
    };
    log.level = "INFO";
    accessLog = {
      filePath = "/var/log/traefik/access.log";
      format = "json";
    };
    certificatesResolvers.letsencrypt.acme = {
      httpChallenge.entryPoint = "web";
      email = "guillaume+letsencrypt@friloux.me";
      storage = "/letsencrypt/acme.json";
      caServer = "https://acme-v02.api.letsencrypt.org/directory";
    };
    # crowdsec sur les entrypoints et non route par route : les routes que
    # pangolin génère passent aussi par le bouncer.
    entryPoints = {
      web = {
        address = ":80";
        http.middlewares = ["crowdsec@file"];
      };
      websecure = {
        address = ":443";
        transport.respondingTimeouts.readTimeout = "30m";
        http3.advertisedPort = 443;
        http = {
          middlewares = ["crowdsec@file"];
          tls.certResolver = "letsencrypt";
          encodedCharacters = {
            allowEncodedSlash = true;
            allowEncodedQuestionMark = true;
          };
        };
      };
    };
    serversTransport.insecureSkipVerify = true;
    ping.entryPoint = "web";
  };

  dynamicConfig = yaml.generate "dynamic_config.yml" {
    http = {
      middlewares = {
        badger.plugin.badger.disableForwardAuth = true;
        crowdsec.plugin.bouncer = {
          enabled = true;
          crowdsecMode = "live";
          crowdsecLapiScheme = "http";
          crowdsecLapiHost = "crowdsec:8080";
          crowdsecLapiKeyFile = "/etc/traefik/crowdsec-bouncer-key";
          # Clé : celle de la LAPI. Défauts gardés (Failure/UnreachableBlock) :
          # si crowdsec ne répond plus, tout est bloqué, comme déjà pour la LAPI
          # en mode live.
          crowdsecAppsecEnabled = true;
          crowdsecAppsecHost = "crowdsec:7422";
        };
        redirect-to-https.redirectScheme.scheme = "https";
      };
      routers = {
        main-app-router-redirect = {
          rule = "Host(`pangolin.friloux.me`)";
          service = "next-service";
          entryPoints = ["web"];
          middlewares = ["redirect-to-https" "badger"];
        };
        next-router = {
          rule = "Host(`pangolin.friloux.me`) && !PathPrefix(`/api/v1`)";
          service = "next-service";
          entryPoints = ["websecure"];
          middlewares = ["badger"];
          tls.certResolver = "letsencrypt";
        };
        api-router = {
          rule = "Host(`pangolin.friloux.me`) && PathPrefix(`/api/v1`)";
          service = "api-service";
          entryPoints = ["websecure"];
          middlewares = ["badger"];
          tls.certResolver = "letsencrypt";
        };
        ws-router = {
          rule = "Host(`pangolin.friloux.me`)";
          service = "api-service";
          entryPoints = ["websecure"];
          middlewares = ["badger"];
          tls.certResolver = "letsencrypt";
        };
      };
      services = {
        next-service.loadBalancer.servers = [{url = "http://pangolin:3002";}];
        api-service.loadBalancer.servers = [{url = "http://pangolin:3000";}];
      };
    };
    tcp.serversTransports = {
      pp-transport-v1.proxyProtocol.version = 1;
      pp-transport-v2.proxyProtocol.version = 2;
    };
  };
in {
  sops = {
    secrets = {
      "services/pangolin/secret" = {};
      # Le dépôt est public : l'IP de la box ne doit pas y apparaître.
      "network/box-ip" = {};
    };
    # Écartées dès le parsing : ni alerte, ni ban, ni signal envoyé à CAPI.
    # La whitelist par défaut ne couvre que les plages privées IPv4 et ::1.
    templates."crowdsec-whitelist.yaml".content = builtins.toJSON {
      name = "friloux/skitarii-whitelist";
      description = "tailnet, skitarii, réseau docker pangolin, box";
      whitelist = {
        reason = "tailnet, skitarii, réseau docker pangolin, box";
        cidr = [
          "100.64.0.0/10" # tailnet
          "fd7a:115c:a1e0::/48" # tailnet
          "5.196.4.180/32" # skitarii
          "2001:41d0:404:200::487d/128" # skitarii
          "fd49:e7d1:9e38::/64" # réseau docker pangolin (ULA)
          "${config.sops.placeholder."network/box-ip"}/32" # box
        ];
      };
    };
    # config.yml porte server.secret : rendu par sops, monté en lecture seule.
    templates."pangolin-config.yml".content = builtins.toJSON {
      gerbil = {
        start_port = 51820;
        base_endpoint = "pangolin.friloux.me";
      };
      app = {
        dashboard_url = "https://pangolin.friloux.me";
        log_level = "info";
        telemetry.anonymous_usage = false;
      };
      domains.domain1.base_domain = "friloux.me";
      server = {
        secret = config.sops.placeholder."services/pangolin/secret";
        cors = {
          origins = ["https://pangolin.friloux.me"];
          methods = ["GET" "POST" "PUT" "DELETE" "PATCH"];
          allowed_headers = ["X-CSRF-Token" "Content-Type"];
          credentials = false;
        };
      };
      flags = {
        require_email_verification = false;
        disable_signup_without_invite = true;
        disable_user_create_org = false;
        allow_raw_resources = true;
      };
      # auth vaut 500/min par défaut, comme global : rien contre le
      # brute-force du login. 10/min est la valeur d'exemple de la doc.
      rate_limits.auth = {
        window_minutes = 1;
        max_requests = 10;
      };
    };
  };

  virtualisation.oci-containers.containers = {
    pangolin = {
      # Édition Enterprise : licence gratuite pour usage personnel, saisie dans
      # l'UI (/admin/license) et liée au host ID du serveur.
      image = "docker.io/fosrl/pangolin:ee-1.25.3"; # renovate
      volumes = [
        "${dataDir}/config:/app/config"
        "${config.sops.templates."pangolin-config.yml".path}:/app/config/config.yml:ro"
      ];
      networks = ["pangolin"];
      # Celui du compose officiel.
      extraOptions = inputs.stc.lib.docker.mkHealthCheck {
        cmd = "curl -f http://localhost:3001/api/v1/";
        startPeriod = "60s";
      };
      labels."stc.docker/health-watch" = "true";
    };

    gerbil = {
      image = "docker.io/fosrl/gerbil:1.5.2"; # renovate
      dependsOn = ["pangolin"];
      cmd = [
        "--reachableAt=http://gerbil:3004"
        "--generateAndSaveKeyTo=/var/config/key"
        "--remoteConfig=http://pangolin:3001/api/v1/"
      ];
      volumes = ["${dataDir}/config:/var/config"];
      # Les ports de traefik sont publiés ici : traefik vit dans le réseau de
      # gerbil.
      ports = [
        "51820:51820/udp"
        "21820:21820/udp"
        "443:443"
        "443:443/udp"
        "80:80"
      ];
      capabilities = {
        NET_ADMIN = true;
        SYS_MODULE = true;
      };
      networks = ["pangolin"];
      # Le serveur HTTP de --reachableAt, par lequel pangolin le pilote.
      extraOptions = inputs.stc.lib.docker.mkHealthCheck {
        cmd = "wget -q -O /dev/null http://localhost:3004/healthz";
      };
      labels."stc.docker/health-watch" = "true";
    };

    traefik = {
      image = "traefik:v3.7.17"; # renovate
      dependsOn = ["gerbil" "crowdsec"];
      cmd = ["--configFile=/etc/traefik/traefik_config.yml"];
      volumes = [
        "${traefikConfig}:/etc/traefik/traefik_config.yml:ro"
        "${dynamicConfig}:/etc/traefik/dynamic_config.yml:ro"
        "${config.sops.secrets."services/crowdsec/bouncer-key".path}:/etc/traefik/crowdsec-bouncer-key:ro"
        "${dataDir}/letsencrypt:/letsencrypt"
        "${dataDir}/traefik-logs:/var/log/traefik"
      ];
      extraOptions =
        ["--network=container:gerbil"]
        # L'entrypoint ping déclaré sur web, lu dans la config statique.
        ++ inputs.stc.lib.docker.mkHealthCheck {
          cmd = "traefik healthcheck --configFile=/etc/traefik/traefik_config.yml";
        };
      labels."stc.docker/health-watch" = "true";
    };

    # Conteneur de la relic STC : elle ne connaît que son propre traefik, on
    # lui ajoute le réseau et les logs de celui-ci.
    crowdsec = {
      volumes = [
        "${dataDir}/traefik-logs:/var/log/traefik:ro"
        "${crowdsecAcquis}:/etc/crowdsec/acquis.d/traefik.yaml:ro"
        "${crowdsecAppsecAcquis}:/etc/crowdsec/acquis.d/appsec.yaml:ro"
        "${config.sops.templates."crowdsec-whitelist.yaml".path}:/etc/crowdsec/parsers/s02-enrich/skitarii-whitelist.yaml:ro"
      ];
      networks = ["pangolin"];
    };
  };

  systemd = {
    # IPv6 sur le réseau (préfixe ULA) : Docker publie alors les ports de
    # gerbil en IPv6 par DNAT ip6tables, qui garde l'adresse du visiteur. Sans
    # ça, l'IPv6 passe par docker-proxy et traefik voit la passerelle Docker,
    # une IP privée que crowdsec ignore. Le script ne recrée pas un réseau
    # existant : changer ces options demande un `docker network rm pangolin`.
    services."docker-network-pangolin" =
      inputs.stc.lib.docker.mkNetwork pkgs "pangolin"
      // {
        script = ''
          docker network inspect pangolin \
            || docker network create --ipv6 --subnet fd49:e7d1:9e38::/64 pangolin
        '';
        before = ["docker-pangolin.service" "docker-gerbil.service" "crowdsec.service"];
        requiredBy = ["docker-pangolin.service" "docker-gerbil.service" "crowdsec.service"];
      };

    tmpfiles.rules = [
      "d ${dataDir}/config 0750 0 0 -"
      "d ${dataDir}/letsencrypt 0700 0 0 -"
      "d ${dataDir}/traefik-logs 0750 0 0 -"
    ];
  };

  # Comme la relic traefik de STC : renommage puis USR1 pour que traefik
  # rouvre son log. Pas de copytruncate, qui perd les lignes écrites pendant
  # la copie, donc des lignes que crowdsec n'aurait jamais lues.
  services.logrotate.settings.traefik = {
    files = "${dataDir}/traefik-logs/access.log";
    frequency = "daily";
    rotate = 14;
    compress = true;
    delaycompress = true;
    missingok = true;
    notifempty = true;
    postrotate = "${pkgs.docker}/bin/docker kill -s USR1 traefik || true";
  };

  # Ouverts pour les cas où docker-proxy prend la connexion sur l'hôte (INPUT)
  # plutôt que le DNAT (FORWARD, hors du pare-feu NixOS).
  networking.firewall = {
    allowedTCPPorts = [80 443];
    allowedUDPPorts = [443 51820 21820];
  };
}
