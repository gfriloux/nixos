{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.zfs-root.boot;
  inherit (lib) types mkDefault mkOption concatMapStrings;
in {
  options.zfs-root.boot = {
    bootDevices = mkOption {
      description = "Specify boot devices";
      type = types.nonEmptyListOf types.str;
    };
    availableKernelModules = mkOption {
      type = types.nonEmptyListOf types.str;
      default = ["uas" "nvme" "ahci"];
    };
  };
  config = {
    zfs-root.fileSystems = {
      datasets = {
        "rpool/nixos/home" = mkDefault "/home";
        "rpool/nixos/var/lib" = mkDefault "/var/lib";
        "rpool/nixos/var/log" = mkDefault "/var/log";
        "rpool/nixos/root" = "/";
        "bpool/nixos/root" = "/boot";
      };
      efiSystemPartitions = map (diskName: diskName + "-part1") cfg.bootDevices;
      swapPartitions = map (diskName: diskName + "-part4") cfg.bootDevices;
    };
    boot = {
      kernelPackages = pkgs.linuxPackages_6_12;
      initrd.availableKernelModules = cfg.availableKernelModules;
      kernel.sysctl = {
        "kernel.unprivileged_userns_clone" = 1; # for appimages
        "fs.file-max" = 640000;
      };
      supportedFilesystems = ["zfs"];
      zfs = {
        devNodes = "/dev/disk/by-id/";
        forceImportRoot = mkDefault false;
      };
      loader = {
        efi = {
          canTouchEfiVariables = false;
          efiSysMountPoint = "/boot/efis/" + (builtins.head cfg.bootDevices) + "-part1";
        };
        generationsDir.copyKernels = true;
        grub = {
          enable = true;
          devices = map (diskName: "/dev/disk/by-id/" + diskName) cfg.bootDevices;
          efiInstallAsRemovable = true;
          copyKernels = true;
          efiSupport = true;
          zfsSupport = true;
          extraInstallCommands = concatMapStrings (diskName: ''
            set -x
            ${pkgs.coreutils-full}/bin/cp -r ${config.boot.loader.efi.efiSysMountPoint}/EFI /boot/efis/${diskName}-part1
            set +x
          '') (builtins.tail cfg.bootDevices);
        };
      };
    };
  };
}
