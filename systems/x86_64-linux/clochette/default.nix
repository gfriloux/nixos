{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    inputs.sops-nix.nixosModules.sops
    ./hardware-configuration.nix
    ./docker-traefik.nix
    ./docker-papra.nix
    ./docker-wow-cp.nix
    ./docker-crowdsec.nix
    ./backup.nix
    ./notify.nix
    ./network.nix
    ./users.nix
  ];

  sops = {
    defaultSopsFile = ../../../secrets/clochette.yaml;
    secrets."users/guillaume/hashed-password".neededForUsers = true;
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

      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
        PubkeyAuthentication = true;
        ChallengeResponseAuthentication = false;
        KbdInteractiveAuthentication = false;
        MaxAuthTries = 3;
        LoginGraceTime = "30s";
        X11Forwarding = false;
        AllowUsers = ["guillaume" "weechat"];
      };
    };
    fail2ban.enable = true;
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

  system.stateVersion = "26.05";
}
