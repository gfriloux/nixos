{
  pkgs,
  config,
  inputs,
  ...
}: {
  imports = [
    inputs.sops-nix.nixosModules.sops
    inputs.disko.nixosModules.disko
    inputs.stc.nixosModules.relics-docker-traefik
    inputs.stc.nixosModules.relics-docker-socket-proxy
    inputs.stc.nixosModules.relics-docker-crowdsec
    inputs.stc.nixosModules.relics-docker-notify
    ./hardware-configuration.nix
    ./disko.nix
    ./backup.nix
    ./docker-borg-ui.nix
    ./docker-uptime-kuma.nix
    ./docker-mealie.nix
    ./docker-papra.nix
    ./docker-wow-cp.nix
    ./users.nix
  ];

  stc.relics.docker = {
    traefik = {
      enable = true;
      image = "traefik:v3.7.8"; # renovate
      acme.email = "guillaume+letsencrypt@friloux.me";
      enableDashboard = true;
      dynamicConfigFile = config.sops.secrets."services/traefik/conf/traefik_dynamic.yml".path;
    };
    socketProxy = {
      enable = true;
      image = "tecnativa/docker-socket-proxy:v0.4.2"; # renovate
    };
    crowdsec = {
      enable = true;
      image = "crowdsecurity/crowdsec:v1.7.8"; # renovate
      dataDir = "/srv/docker/crowdsec.rogueleader.home";
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
    defaultSopsFile = ../../../secrets/RogueLeader.yaml;
    age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
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

  boot.loader.grub.enable = true;

  time.timeZone = "Europe/Paris";
  i18n.defaultLocale = "fr_FR.UTF-8";

  networking.hostName = "RogueLeader";

  nix.settings.trusted-users = ["root" "guillaume"];

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      KbdInteractiveAuthentication = false;
      MaxAuthTries = 3;
      LoginGraceTime = "30s";
      X11Forwarding = false;
      AllowUsers = ["guillaume"];
    };
  };

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

  system.stateVersion = "25.11";
}
