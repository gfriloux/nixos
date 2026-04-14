{pkgs, ...}: {
  imports = [
    #inputs.sops-nix.nixosModules.sops
    ./boot.nix
    ./filesystems.nix
    ./network.nix
    ./services.nix
    ./security.nix
    ./users.nix
    ./proot.nix
  ];

  #sops.defaultSopsFile = ../../../secrets/example.yaml;
  #sops.secrets."users/root/password" = { };

  boot.initrd.kernelModules = ["amdgpu"];
  hardware.firmware = [pkgs.linux-firmware];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      libvdpau
      #amdvlk
      #vaapiVdpau
      libva-vdpau-driver
    ];
  };

  nixpkgs.config.allowUnfree = true;

  programs.fish.enable = true;

  #  system.autoUpgrade.enable = true;
  #  system.autoUpgrade.allowReboot = true;
  #  system.autoUpgrade.channel = "https://channels.nixos.org/nixos-unstable";

  console = {
    font = "Lat2-Terminus16";
    keyMap = "fr";
  };

  i18n = {
    defaultLocale = "fr_FR.UTF-8";
  };

  systemd.user.services.wireplumber.wantedBy = ["default.target"];

  xdg.portal = {
    enable = true;
    extraPortals = [pkgs.xdg-desktop-portal-gtk];
    config.common.default = "*";
  };

  boot.zfs.forceImportRoot = false;

  nix = {
    settings.experimental-features = ["nix-command" "flakes"];
    optimise.automatic = true;
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 5d";
    };
  };

  virtualisation = {
    docker = {
      enable = true;
      storageDriver = "zfs";
    };
    waydroid.enable = true;
  };

  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.droid-sans-mono
    nerd-fonts.iosevka
  ];

  environment.systemPackages = with pkgs; [
    steam
    appimage-run
    steam-run
    flatpak-builder
    appstream
    appstream-glib
    xwayland-satellite
    wl-clipboard
    linux-wallpaperengine
    w3m
    bc
    bash
    iotop
    file
    bonnie
    home-manager
    wl-clipboard
    lm_sensors
    pmutils
    pavucontrol
    pulsemixer
    ntfs3g
    samba
    docker-compose
    ueberzug
    offlineimap
    protonup-ng
    rustup
    gcc
    scanmem
    (pkgs.python3.withPackages (python-pkgs:
      with python-pkgs; [
        # select Python packages here
        tqdm
        inquirerpy
        requests
      ]))
    yubikey-personalization
    age
  ];

  #fileSystems."/data" = {
  #      device = "/dev/disk/by-id/wwn-0x5000c500f77f56e2-part1";
  #      fsType = "ext4";
  #};

  fileSystems."/data2" = {
    device = "/dev/disk/by-id/wwn-0x5000c500c78528e7-part1";
    fsType = "ext4";
  };

  system.stateVersion = "24.11";
}
