{
  config,
  lib,
  pkgs,
  ...
}: let
  bootDevices = ["nvme-Samsung_SSD_980_PRO_1TB_S5GXNL0W810368E" "nvme-Samsung_SSD_980_PRO_1TB_S5GXNL0W810454N"];
  availableKernelModules = ["xhci_pci" "ehci_pci" "nvme" "usb_storage" "usbhid" "sd_mod" "amdgpu"];
  inherit (lib) mkDefault concatMapStrings;
in {
  config = {
    zfs-root.fileSystems = {
      datasets = {
        "rpool/nixos/home" = mkDefault "/home";
        "rpool/nixos/var/lib" = mkDefault "/var/lib";
        "rpool/nixos/var/log" = mkDefault "/var/log";
        "rpool/nixos/root" = "/";
        "bpool/nixos/root" = "/boot";
      };
      efiSystemPartitions = map (diskName: diskName + "-part1") bootDevices;
      swapPartitions = map (diskName: diskName + "-part4") bootDevices;
    };
    boot = {
      kernelPackages = pkgs.linuxPackages_6_12;
      initrd.availableKernelModules = availableKernelModules;
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
