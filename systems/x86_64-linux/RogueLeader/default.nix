{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    inputs.sops-nix.nixosModules.sops
    inputs.disko.nixosModules.disko
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

  kuri = {
    notify-docker.enable = true;
    docker-traefik.enable = true;
    docker-crowdsec = {
      enable = true;
      dataDir = "/srv/docker/crowdsec.rogueleader.home";
    };
  };

  sops = {
    defaultSopsFile = ../../../secrets/RogueLeader.yaml;
    age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
    secrets."users/guillaume/hashed-password".neededForUsers = true;
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
