{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.zfs-root.boot;
  inherit (lib) mkIf types mkDefault mkOption mkMerge;
  inherit (builtins) head toString map tail;
in {
  options.zfs-root.boot = {
    enable = mkOption {
      description = "Enable root on ZFS support";
      type = types.bool;
      default = true;
    };
    bootDevices = mkOption {
      description = "Specify boot devices";
      type = types.nonEmptyListOf types.str;
    };
    availableKernelModules = mkOption {
      type = types.nonEmptyListOf types.str;
      default = ["uas" "nvme" "ahci"];
    };
    partitionScheme = mkOption {
      default = {
        biosBoot = "-part5";
        efiBoot = "-part1";
        swap = "-part4";
        bootPool = "-part2";
        rootPool = "-part3";
      };
      description = "Describe on disk partitions";
      type = types.attrsOf types.str;
    };
  };
  config = mkIf cfg.enable (mkMerge [
    {
      zfs-root.fileSystems.datasets = {
        "rpool/nixos/home" = mkDefault "/home";
        "rpool/nixos/var/lib" = mkDefault "/var/lib";
        "rpool/nixos/var/log" = mkDefault "/var/log";
        "rpool/nixos/root" = "/";
        "bpool/nixos/root" = "/boot";
      };
    }
    {
      zfs-root.fileSystems = {
        efiSystemPartitions = map (diskName: diskName + cfg.partitionScheme.efiBoot) cfg.bootDevices;
        swapPartitions = map (diskName: diskName + cfg.partitionScheme.swap) cfg.bootDevices;
      };
      boot = {
        kernelPackages = pkgs.linuxPackages_6_12;
        initrd.availableKernelModules = cfg.availableKernelModules;
        kernelParams = [];
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
            efiSysMountPoint = "/boot/efis/" + (head cfg.bootDevices) + cfg.partitionScheme.efiBoot;
          };
          generationsDir.copyKernels = true;
          grub = {
            enable = true;
            devices = map (diskName: "/dev/disk/by-id/" + diskName) cfg.bootDevices;
            efiInstallAsRemovable = true;
            copyKernels = true;
            efiSupport = true;
            zfsSupport = true;
            extraInstallCommands = toString (map (diskName: ''
              set -x
              ${pkgs.coreutils-full}/bin/cp -r ${config.boot.loader.efi.efiSysMountPoint}/EFI /boot/efis/${diskName}${cfg.partitionScheme.efiBoot}
              set +x
            '') (tail cfg.bootDevices));
          };
        };
      };
    }
  ]);
}
