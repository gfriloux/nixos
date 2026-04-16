{pkgs, ...}: {
  imports = [
    ./boot.nix
    ./filesystems.nix
    ./services.nix
    ./security.nix
    ./users.nix
  ];

  time.timeZone = "Europe/Paris";

  networking = {
    hostName = "exampleHost";
    hostId = "21ed29b1";
    networkmanager.enable = true;
    firewall.enable = false;
  };

  zfs-root.boot = {
    bootDevices = ["nvme-Samsung_SSD_980_PRO_1TB_S5GXNL0W810368E" "nvme-Samsung_SSD_980_PRO_1TB_S5GXNL0W810454N"];
    availableKernelModules = ["xhci_pci" "ehci_pci" "nvme" "usb_storage" "usbhid" "sd_mod" "amdgpu"];
  };

  boot.initrd.kernelModules = ["amdgpu"];
  hardware.firmware = [pkgs.linux-firmware];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      libvdpau
      libva-vdpau-driver
    ];
  };

  nixpkgs.config.allowUnfree = true;

  programs.fish.enable = true;

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
        tqdm
        inquirerpy
        requests
      ]))
    yubikey-personalization
    age
  ];

  fileSystems."/data2" = {
    device = "/dev/disk/by-id/wwn-0x5000c500c78528e7-part1";
    fsType = "ext4";
  };

  system.stateVersion = "24.11";
}
