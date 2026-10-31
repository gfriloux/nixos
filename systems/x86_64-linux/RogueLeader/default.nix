{
  pkgs,
  config,
  inputs,
  ...
}: {
  imports = [
    inputs.sops-nix.nixosModules.sops
    inputs.disko.nixosModules.disko
    inputs.stc.nixosModules.relics-docker-notify
    inputs.stc.nixosModules.relics-hardening-ssh
    inputs.stc.nixosModules.relics-nix-housekeeping
    ./hardware-configuration.nix
    ./disko.nix
    ./backup.nix
    ./docker-borg-ui.nix
    ./docker-uptime-kuma.nix
    ./docker-mealie.nix
    ./docker-newt.nix
    ./docker-papra.nix
    ./docker-wow-cp.nix
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

    # No fail2ban: SSH is LAN-only here, and the relic's PerSourcePenalties
    # already blocks sources that fail auth, inside sshd itself.
    hardening.ssh.enable = true;
  };

  sops = {
    defaultSopsFile = ../../../secrets/RogueLeader.yaml;
    age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
    secrets = {
      "users/guillaume/hashed-password".neededForUsers = true;
      "services/ntfy/topic" = {};
    };
  };

  boot.loader.grub.enable = true;

  time.timeZone = "Europe/Paris";
  i18n.defaultLocale = "fr_FR.UTF-8";

  networking.hostName = "RogueLeader";

  nix.settings.trusted-users = ["root" "guillaume"];

  services.openssh.settings.AllowUsers = ["guillaume"];

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

  system.stateVersion = "25.11";
}
