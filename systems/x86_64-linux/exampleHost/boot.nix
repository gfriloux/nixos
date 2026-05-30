{
  lib,
  pkgs,
  ...
}: let
  bootDevices = [
    "nvme-Samsung_SSD_980_PRO_1TB_S5GXNL0W810368E"
    "nvme-Samsung_SSD_980_PRO_1TB_S5GXNL0W810454N"
  ];

  availableKernelModules = ["xhci_pci" "ehci_pci" "nvme" "usb_storage" "usbhid" "sd_mod" "amdgpu"];

  datasets = {
    "rpool/nixos/home" = "/home";
    "rpool/nixos/var/lib" = "/var/lib";
    "rpool/nixos/var/log" = "/var/log";
    "rpool/nixos/root" = "/";
    "bpool/nixos/root" = "/boot";
  };

  zfsFileSystems =
    lib.mapAttrsToList (dataset: mountpoint: {
      "${mountpoint}" = {
        device = dataset;
        fsType = "zfs";
        options = ["X-mount.mkdir"];
        neededForBoot = true;
      };
    })
    datasets;

  efiFileSystems =
    map (diskName: {
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
    bootDevices;

  efiSysMountPoint = "/boot/efis/${builtins.head bootDevices}-part1";
in {
  config = {
    fileSystems = lib.mkMerge (zfsFileSystems ++ efiFileSystems);

    swapDevices = lib.mkDefault (map (diskName: {
        device = "/dev/disk/by-id/${diskName}-part4";
        discardPolicy = "both";
        randomEncryption = {
          enable = true;
          allowDiscards = true;
        };
      })
      bootDevices);

    boot = {
      initrd.availableKernelModules = availableKernelModules;
      kernel.sysctl = {
        "fs.file-max" = 640000;
        "kernel.kptr_restrict" = 2; # cache les adresses kernel dans /proc
        "kernel.dmesg_restrict" = 1; # dmesg réservé à root
        "kernel.unprivileged_bpf_disabled" = 1; # BPF restreint à root
        "net.core.bpf_jit_harden" = 2; # durcit le JIT BPF
        "kernel.perf_event_paranoid" = 3; # restreint perf_events
        "kernel.yama.ptrace_scope" = 1; # ptrace limité au parent uniquement
      };
      blacklistedKernelModules = [
        # DMA attack vector (FireWire)
        "firewire-core"
        "firewire-ohci"
        "firewire-sbp2"
        # Unused network protocols (frequent CVE vectors)
        "dccp"
        "sctp"
        "rds"
        "tipc"
      ];
      zfs.devNodes = "/dev/disk/by-id/";
      loader = {
        efi = {
          canTouchEfiVariables = false;
          inherit efiSysMountPoint;
        };
        generationsDir.copyKernels = true;
        grub = {
          enable = true;
          devices = map (diskName: "/dev/disk/by-id/${diskName}") bootDevices;
          efiInstallAsRemovable = true;
          copyKernels = true;
          efiSupport = true;
          zfsSupport = true;
          extraInstallCommands = ''
            set -x
            ${pkgs.coreutils-full}/bin/cp -r ${efiSysMountPoint}/EFI /boot/efis/${builtins.elemAt bootDevices 1}-part1
            set +x
          '';
        };
      };
    };
  };
}
