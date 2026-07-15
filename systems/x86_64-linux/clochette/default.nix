{
  pkgs,
  config,
  inputs,
  ...
}: {
  imports = [
    inputs.sops-nix.nixosModules.sops
    inputs.stc.nixosModules.relics-docker-traefik
    inputs.stc.nixosModules.relics-docker-socket-proxy
    inputs.stc.nixosModules.relics-docker-crowdsec
    inputs.stc.nixosModules.relics-docker-notify
    ./hardware-configuration.nix
    ./docker-immich.nix
    ./backup.nix
    ./network.nix
    ./users.nix
    ./docker-crowdsec-manager.nix
  ];

  stc.relics.docker = {
    traefik = {
      enable = true;
      image = "traefik:v3.7.6"; # renovate
      acme.email = "guillaume+letsencrypt@friloux.me";
      enableDashboard = true;
      dynamicConfigFile = config.sops.secrets."services/traefik/conf/traefik_dynamic.yml".path;
    };
    socketProxy = {
      enable = true;
      image = "tecnativa/docker-socket-proxy:0.3.0"; # renovate
    };
    crowdsec = {
      enable = true;
      image = "crowdsecurity/crowdsec:v1.7.8"; # renovate
      dataDir = "/srv/docker/crowdsec.clochette.friloux.me";
      envFile = config.sops.secrets."services/crowdsec/env".path;
    };
    notify = {
      enable = true;
      notifyCommand = ''
        ${pkgs.curl}/bin/curl -s \
          -H "Title: [$STC_NOTIFY_HOSTNAME] $STC_NOTIFY_SERVICE en défaut" \
          -d "$STC_NOTIFY_SERVICE est passé en état failed" \
          "https://ntfy.sh/$(cat ${config.sops.secrets."services/ntfy/topic".path})"
      '';
    };
  };

  sops = {
    defaultSopsFile = ../../../secrets/clochette.yaml;
    secrets = {
      "users/guillaume/hashed-password".neededForUsers = true;
      "services/ntfy/topic" = {};
      "services/crowdsec/env" = {};
      "services/traefik/conf/traefik_dynamic.yml" = {
        owner = "root";
        group = "root";
        mode = "0400";
        path = "/srv/docker/traefik/conf/traefik_dynamic.yml";
      };
    };
  };

  boot = {
    loader.grub = {
      enable = true;
      device = "/dev/sda";
    };
    kernelParams = ["console=ttyS1"];
  };

  time.timeZone = "Europe/Paris";

  i18n.defaultLocale = "fr_FR.UTF-8";

  nix.settings.trusted-users = ["root" "guillaume" "clochette"];

  services = {
    openssh = {
      enable = true;
      openFirewall = false;

      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
        KbdInteractiveAuthentication = false;
        MaxAuthTries = 3;
        LoginGraceTime = "30s";
        X11Forwarding = false;
        AllowUsers = ["guillaume" "weechat"];
      };
    };
    tailscale.enable = true;
    fail2ban.enable = true;
  };

  networking.firewall.trustedInterfaces = ["tailscale0"];

  virtualisation = {
    docker = {
      enable = true;
      autoPrune.enable = true;
    };
    oci-containers.backend = "docker";
  };

  programs.fish.enable = true;
  environment.systemPackages = with pkgs; [
    docker-compose
  ];

  system.stateVersion = "26.05";
}
