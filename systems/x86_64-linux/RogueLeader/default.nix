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
    ./docker-traefik.nix
    ./docker-crowdsec.nix
    ./notify.nix
    ./users.nix
  ];

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
