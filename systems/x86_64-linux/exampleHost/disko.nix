{lib, ...}: let
  diskNames = [
    "nvme-Samsung_SSD_980_PRO_1TB_S5GXNL0W810368E"
    "nvme-Samsung_SSD_980_PRO_1TB_S5GXNL0W810454N"
  ];

  mkDisk = diskName: {
    type = "disk";
    device = "/dev/disk/by-id/${diskName}";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot/efis/${diskName}-part1";
            mountOptions = [
              "x-systemd.idle-timeout=1min"
              "x-systemd.automount"
              "noauto"
              "nofail"
              "noatime"
              "X-mount.mkdir"
            ];
          };
        };
        bpool = {
          size = "4G";
          content = {
            type = "zfs";
            pool = "bpool";
          };
        };
        rpool = {
          size = "920G";
          content = {
            type = "zfs";
            pool = "rpool";
          };
        };
        swap = {
          size = "4G";
          content = {
            type = "swap";
            randomEncryption = true;
          };
        };
        grub = {
          size = "1M";
          type = "EF02";
        };
      };
    };
  };
in {
  # enableConfig = false: boot.nix gère fileSystems sur le système courant.
  # Pour une réinstallation avec nixos-anywhere, passer à true et retirer les
  # fileSystems ZFS et swapDevices de boot.nix.
  disko = {
    enableConfig = false;
    devices = {
      disk = lib.listToAttrs (lib.imap0 (i: name: {
          name = "nvme${toString i}";
          value = mkDisk name;
        })
        diskNames);

      zpool = {
        bpool = {
          type = "zpool";
          mode = "mirror";
          options = {
            ashift = "12";
            autotrim = "on";
            compatibility = "grub2";
          };
          datasets = {
            "nixos/root" = {
              type = "zfs_fs";
              mountpoint = "/boot";
              options.mountpoint = "legacy";
            };
          };
        };

        rpool = {
          type = "zpool";
          mode = "mirror";
          options = {
            ashift = "12";
            autotrim = "on";
          };
          datasets = {
            "nixos/root" = {
              type = "zfs_fs";
              mountpoint = "/";
              options.mountpoint = "legacy";
            };
            "nixos/home" = {
              type = "zfs_fs";
              mountpoint = "/home";
              options.mountpoint = "legacy";
            };
            "nixos/var/lib" = {
              type = "zfs_fs";
              mountpoint = "/var/lib";
              options.mountpoint = "legacy";
            };
            "nixos/var/log" = {
              type = "zfs_fs";
              mountpoint = "/var/log";
              options.mountpoint = "legacy";
            };
          };
        };
      };
    };
  };
}
