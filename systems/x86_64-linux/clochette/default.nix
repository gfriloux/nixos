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
    ./backup.nix
  ];

  sops = {
    defaultSopsFile = ../../../secrets/clochette.yaml;

    secrets = {
      "services/papra/env" = {
        owner = "papra";
        group = "papra";
      };
      "services/borg/passphrase" = {};
      "services/borg/key/private" = {};
      "services/wow-cp/env_bookstack" = {};
      "services/wow-cp/env_mariadb" = {};
    };
  };

  boot = {
    loader.grub = {
      enable = true;
      device = "/dev/sda";
    };
    kernelParams = ["console=ttyS1"];
  };

  networking = {
    hostName = "clochette";
    networkmanager.enable = true;
    interfaces.eth0 = {
      ipv4.addresses = [
        {
          address = "51.159.34.135";
          prefixLength = 24;
        }
      ];
    };
    defaultGateway = "51.159.34.1";
    nameservers = ["51.159.47.28" "51.159.47.26"];
  };

  time.timeZone = "Europe/Paris";

  i18n.defaultLocale = "fr_FR.UTF-8";

  nix.settings.trusted-users = ["root" "guillaume" "clochette"];

  services.openssh.enable = true;

  security.sudo.wheelNeedsPassword = false;

  virtualisation = {
    docker = {
      enable = true;
      autoPrune.enable = true;
    };
    oci-containers.backend = "docker";
  };

  users.users.guillaume = {
    createHome = true;
    isNormalUser = true;
    linger = true;
    home = "/home/guillaume";
    description = "Moi";
    extraGroups = ["wheel" "docker"];
    useDefaultShell = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIETPEOCEETy3EHFswjsoEsMmu4i7TUPCXwPrhVsjH8rE guillaume+perso@friloux.me"
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIFE9OazubAILNGPXMxVPBK4vgFVNth2G67JWN3wnB4+tAAAADXNzaDpjbG9jaGV0dGU= clochette@friloux.me"
    ];
    shell = pkgs.fish;
  };

  users.users.weechat = {
    createHome = true;
    isNormalUser = true;
    linger = true;
    home = "/home/weechat";
    description = "Moi";
    useDefaultShell = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIETPEOCEETy3EHFswjsoEsMmu4i7TUPCXwPrhVsjH8rE guillaume+perso@friloux.me"
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIP69OQvGEPoEZU8pSCRKDprle3C9UGqbt/52t6NG5GWYAAAADnNzaDphcHB3ZWVjaGF0 weechat@irc.friloux.me"
    ];
    shell = pkgs.fish;
  };

  programs.fish.enable = true;
  environment.systemPackages = with pkgs; [
    docker-compose
  ];

  system.stateVersion = "26.05";
}
