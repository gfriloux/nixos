{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    inputs.sops-nix.nixosModules.sops
    inputs.disko.nixosModules.disko
    inputs.stc.nixosModules.relics-zfs
    inputs.stc.nixosModules.cogitator-workstation
    inputs.stc.nixosModules.cogitator-gaming
    ./boot.nix
    ./disko.nix
    ./services.nix
    ./users.nix
  ];

  sops = {
    defaultSopsFile = ../../../secrets/kuri_exampleHost.yaml;
    age.keyFile = "/etc/sops/age/keys.txt";
    secrets."users/kuri/hashed-password".neededForUsers = true;
  };

  systemd.tmpfiles.rules = [
    "d /etc/sops/age 0750 root users -"
    "z /etc/sops/age/keys.txt 0640 root users -"
  ];

  time.timeZone = "Europe/Paris";

  networking = {
    hostName = "exampleHost";
    hostId = "21ed29b1";
    networkmanager.enable = true;
    firewall.enable = true;
  };

  hardware.firmware = [pkgs.linux-firmware];

  nixpkgs.config.allowUnfree = true;

  programs.fish.enable = true;

  console = {
    font = "Lat2-Terminus16";
    keyMap = "fr";
  };

  i18n.defaultLocale = "fr_FR.UTF-8";

  stc = {
    relics = {
      zfs.enable = true;
      plasma6 = {
        keyboardLayout = "fr";
        sddmTheme = "catppuccin-mocha-mauve";
      };
      amdGpu.initrd = true;
    };
    # Workstation profile: Plasma desktop + hardening (kernel/network/modules) +
    # YubiKey. Filesystem hardening stays off — hidepid=2 / /tmp noexec would
    # break KDE polkit and Steam/Proton on this gaming desktop.
    cogitator.workstation = {
      enable = true;
      desktop = "plasma";
      hardening.filesystem.enable = false;
    };
    cogitator.gaming.enable = true;
  };

  nix = {
    settings.experimental-features = ["nix-command" "flakes"];
    settings.allowed-users = ["kuri"];
    optimise.automatic = true;
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 5d";
    };
  };

  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.droid-sans-mono
    nerd-fonts.iosevka
  ];

  environment.systemPackages = with pkgs; [
    xwayland-satellite
    wl-clipboard
    bc
    iotop
    file
    home-manager
    lm_sensors
    pmutils
    ntfs3g
  ];

  fileSystems."/data2" = {
    device = "/dev/disk/by-id/wwn-0x5000c500c78528e7-part1";
    fsType = "ext4";
    options = ["noatime" "nofail"];
  };

  system.stateVersion = "24.11";
}
