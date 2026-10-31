{
  pkgs,
  config,
  inputs,
  ...
}: {
  imports = [
    inputs.sops-nix.nixosModules.sops
    inputs.stc.nixosModules.relics-docker-notify
    inputs.stc.nixosModules.relics-hardening-ssh
    inputs.stc.nixosModules.relics-nix-housekeeping
    ./hardware-configuration.nix
    ./docker-immich.nix
    ./docker-newt.nix
    ./backup.nix
    ./network.nix
    ./users.nix
  ];

  stc.relics = {
    docker = {
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

    # Weekly GC (30 days), GC during a build below 5 GiB free, store
    # deduplication, builds that yield to the containers, journal capped at
    # 500M / 1 month (#73).
    nixHousekeeping.enable = true;

    hardening.ssh.enable = true;
  };

  sops = {
    defaultSopsFile = ../../../secrets/clochette.yaml;
    secrets = {
      "users/guillaume/hashed-password".neededForUsers = true;
      "services/ntfy/topic" = {};
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

  nix.settings.trusted-users = ["root" "guillaume"];

  services = {
    openssh = {
      openFirewall = false;
      settings.AllowUsers = ["guillaume" "weechat"];
    };
    # No fail2ban: its only jail was sshd, which is reachable from the
    # tailnet only, and the ssh relic's PerSourcePenalties already blocks
    # failing sources inside sshd. The web side is covered by skitarii's
    # CrowdSec, in front of the pangolin gateway.
    tailscale.enable = true;
  };

  networking.firewall.trustedInterfaces = ["tailscale0"];

  virtualisation = {
    # Pas d'autoPrune : son timer hebdo est Persistent, donc il rattrape au boot
    # un créneau manqué et lance `docker system prune -f` avant que les
    # conteneurs aient rejoint leurs réseaux. Les réseaux sont alors unused et
    # supprimés, et tout ce qui les utilise échoue sur "network not found".
    docker.enable = true;
    oci-containers.backend = "docker";
  };

  programs.fish.enable = true;
  environment.systemPackages = with pkgs; [
    docker-compose
  ];

  system.stateVersion = "26.05";
}
