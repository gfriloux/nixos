{
  config,
  inputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.sops-nix.nixosModules.sops
    inputs.disko.nixosModules.disko
    inputs.stc.nixosModules.relics-docker-crowdsec
    inputs.stc.nixosModules.relics-docker-notify
    inputs.stc.nixosModules.relics-hardening-ssh
    inputs.stc.nixosModules.relics-nix-housekeeping
    ./hardware-configuration.nix
    ./disko.nix
    ./network.nix
    ./users.nix
    ./docker-pangolin.nix
    ./docker-crowdsec-manager.nix
    ./backup.nix
  ];

  stc.relics = {
    # Sans la relic traefik : celui de pangolin est local (docker-pangolin.nix),
    # qui branche aussi crowdsec sur son réseau et ses logs.
    docker.crowdsec = {
      enable = true;
      image = "crowdsecurity/crowdsec:v1.8.1"; # renovate
      dataDir = "/srv/docker/crowdsec.skitarii.friloux.me";
      envFile = config.sops.templates."crowdsec.env".path;
    };
    # -4 --fail : voir le postHook de backup.nix (quota IPv6 de ntfy.sh épuisé
    # sur le /64 OVH partagé).
    docker.notify = {
      enable = true;
      notifyCommand = ''
        ${pkgs.curl}/bin/curl -4 -sS --fail -o /dev/null \
          -H "Title: [$STC_NOTIFY_HOSTNAME] $STC_NOTIFY_SERVICE en défaut" \
          -d "$STC_NOTIFY_SERVICE est passé en état failed" \
          "https://ntfy.sh/$(cat ${config.sops.secrets."services/ntfy/topic".path})"
      '';
    };

    nixHousekeeping.enable = true;
    hardening.ssh.enable = true;
  };

  sops = {
    defaultSopsFile = ../../../secrets/skitarii.yaml;
    # La clé hôte est générée avant l'installation et déposée par
    # nixos-anywhere (--extra-files), pour que sops marche dès le premier boot.
    age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
    secrets = {
      "users/guillaume/hashed-password".neededForUsers = true;
      "services/crowdsec/bouncer-key" = {};
      "services/crowdsec/enroll-key" = {};
      "services/ntfy/topic" = {};
    };
    # crowdsec enregistre lui-même le bouncer avec cette clé au démarrage ;
    # traefik lit la même clé dans un fichier (docker-pangolin.nix).
    # ENROLL_KEY : enrôlement à la console app.crowdsec.net (alertes,
    # blocklists et allowlists de la console). L'image le rejoue à chaque
    # démarrage ; une fois enrôlé, cscli répond par un simple warning.
    templates."crowdsec.env".content = ''
      COLLECTIONS=crowdsecurity/traefik crowdsecurity/http-cve
      BOUNCER_KEY_traefik=${config.sops.placeholder."services/crowdsec/bouncer-key"}
      ENROLL_KEY=${config.sops.placeholder."services/crowdsec/enroll-key"}
      ENROLL_INSTANCE_NAME=skitarii
    '';
  };

  boot.loader.grub.enable = true;

  time.timeZone = "Europe/Paris";

  i18n.defaultLocale = "fr_FR.UTF-8";

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

  system.stateVersion = "26.05";
}
