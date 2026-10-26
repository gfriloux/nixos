{
  config,
  inputs,
  pkgs,
  ...
}: let
  dataDir = "/srv/docker/pangolin.friloux.me";
  yaml = pkgs.formats.yaml {};

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
    experimental.plugins.badger = {
      moduleName = "github.com/fosrl/badger";
      # Pas v1.8.0 : elle échoue au contrôle d'intégrité du registre de
      # plugins traefik, qui désactive alors tous les plugins (note de
      # release badger, traefik/traefik#14115).
      version = "v1.7.0";
    };
    log.level = "INFO";
    certificatesResolvers.letsencrypt.acme = {
      httpChallenge.entryPoint = "web";
      email = "guillaume+letsencrypt@friloux.me";
      storage = "/letsencrypt/acme.json";
      caServer = "https://acme-v02.api.letsencrypt.org/directory";
    };
    entryPoints = {
      web.address = ":80";
      websecure = {
        address = ":443";
        transport.respondingTimeouts.readTimeout = "30m";
        http3.advertisedPort = 443;
        http = {
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
    secrets."services/pangolin/secret" = {};
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
    };
  };

  virtualisation.oci-containers.containers = {
    pangolin = {
      image = "docker.io/fosrl/pangolin:1.25.3"; # renovate
      volumes = [
        "${dataDir}/config:/app/config"
        "${config.sops.templates."pangolin-config.yml".path}:/app/config/config.yml:ro"
      ];
      networks = ["pangolin"];
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
    };

    traefik = {
      image = "traefik:v3.7.16"; # renovate
      dependsOn = ["gerbil"];
      cmd = ["--configFile=/etc/traefik/traefik_config.yml"];
      volumes = [
        "${traefikConfig}:/etc/traefik/traefik_config.yml:ro"
        "${dynamicConfig}:/etc/traefik/dynamic_config.yml:ro"
        "${dataDir}/letsencrypt:/letsencrypt"
      ];
      extraOptions = ["--network=container:gerbil"];
    };
  };

  systemd = {
    services."docker-network-pangolin" =
      inputs.stc.lib.docker.mkNetwork pkgs "pangolin"
      // {
        before = ["docker-pangolin.service" "docker-gerbil.service"];
        requiredBy = ["docker-pangolin.service" "docker-gerbil.service"];
      };

    tmpfiles.rules = [
      "d ${dataDir}/config 0750 0 0 -"
      "d ${dataDir}/letsencrypt 0700 0 0 -"
    ];
  };

  # Avec le userland-proxy de Docker, l'IPv6 entre par INPUT : il faut ouvrir.
  networking.firewall = {
    allowedTCPPorts = [80 443];
    allowedUDPPorts = [443 51820 21820];
  };
}
