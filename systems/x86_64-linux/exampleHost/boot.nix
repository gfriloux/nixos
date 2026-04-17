{
  config,
  lib,
  pkgs,
  ...
}: let
  bootDevices = ["nvme-Samsung_SSD_980_PRO_1TB_S5GXNL0W810368E" "nvme-Samsung_SSD_980_PRO_1TB_S5GXNL0W810454N"];
  availableKernelModules = ["xhci_pci" "ehci_pci" "nvme" "usb_storage" "usbhid" "sd_mod" "amdgpu"];
  datasets = {
    "rpool/nixos/home" = "/home";
    "rpool/nixos/var/lib" = "/var/lib";
    "rpool/nixos/var/log" = "/var/log";
    "rpool/nixos/root" = "/";
    "bpool/nixos/root" = "/boot";
  };
  inherit (lib) mkDefault mkMerge mapAttrsToList concatMapStrings;
in {
  config = {
    fileSystems = mkMerge (
      mapAttrsToList (dataset: mountpoint: {
        "${mountpoint}" = {
          device = dataset;
          fsType = "zfs";
          options = ["X-mount.mkdir" "noatime"];
          neededForBoot = true;
        };
      })
      datasets
      ++ map (diskName: {
        "/boot/efis/${diskName}-part1" = {
          device = "/dev/disk/by-id/${diskName}-part1";
          fsType = "vfat";
          options = [
            "x-systemd.idle-timeout=1min"
            "x-systemd.automount"
            "noauto"
            "nofail"
            "noatime"
            "X-mount.mkdir"
          ];
        };
      })
      bootDevices
    );

    swapDevices = mkDefault (map (diskName: {
        device = "/dev/disk/by-id/${diskName}-part4";
        discardPolicy = "both";
        randomEncryption = {
          enable = true;
          allowDiscards = true;
        };
      })
      bootDevices);

    boot = {
      kernelPackages = pkgs.linuxPackages_6_12;
      initrd.availableKernelModules = availableKernelModules;
      initrd.kernelModules = ["amdgpu"];
      kernel.sysctl = {
        "kernel.unprivileged_userns_clone" = 1; # for appimages
        "fs.file-max" = 640000;
      };
      supportedFilesystems = ["zfs"];
      zfs.devNodes = "/dev/disk/by-id/";
      loader = {
        efi = {
          canTouchEfiVariables = false;
          efiSysMountPoint = "/boot/efis/" + (builtins.head bootDevices) + "-part1";
        };
        generationsDir.copyKernels = true;
        grub = {
          enable = true;
          devices = map (diskName: "/dev/disk/by-id/" + diskName) bootDevices;
          efiInstallAsRemovable = true;
          copyKernels = true;
          efiSupport = true;
          zfsSupport = true;
          extraInstallCommands = concatMapStrings (diskName: ''
            set -x
            ${pkgs.coreutils-full}/bin/cp -r ${config.boot.loader.efi.efiSysMountPoint}/EFI /boot/efis/${diskName}-part1
            set +x
          '') (builtins.tail bootDevices);
        };
      };
    };
  };
}
