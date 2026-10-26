_: {
  disko.devices.disk.main = {
    type = "disk";
    # En boot normal, le seul disque est sda. En rescue OVH, le disque de
    # rescue prend sda et celui-ci devient sdb : une réinstallation depuis le
    # rescue doit passer temporairement à /dev/sdb, puis revenir ici après le
    # premier boot (disko en tire boot.loader.grub.devices). Les by-id ne
    # servent à rien, ils suivent l'adresse SCSI et changent aussi.
    device = "/dev/sda";
    content = {
      type = "gpt";
      partitions = {
        boot = {
          size = "1M";
          type = "EF02";
        };
        swap = {
          size = "2G";
          content.type = "swap";
        };
        root = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
      };
    };
  };
}
