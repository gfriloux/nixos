{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    inputs.sops-nix.nixosModules.sops
    ./hardware-configuration.nix
    ./docker-immich.nix
    ./backup.nix
    ./network.nix
    ./users.nix
    ./docker-crowdsec-manager.nix
  ];

  kuri = {
    notify-docker.enable = true;
    docker-traefik.enable = true;
    docker-crowdsec = {
      enable = true;
      dataDir = "/srv/docker/crowdsec.clochette.friloux.me";
    };
  };

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
