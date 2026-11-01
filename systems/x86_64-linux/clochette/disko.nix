_: {
  # Pas encore importé : clochette tourne toujours sur hardware-configuration.nix
  # (MBR, partitions par UUID). disko monte par partlabel, que le MBR n'a pas :
  # l'importer sur la machine actuelle casserait le boot. On bascule à la
  # prochaine réinstallation (docs/.../operations/reinstall-clochette.md) :
  # importer ce fichier, retirer fileSystems et swapDevices de
  # hardware-configuration.nix, puis nixos-anywhere.
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/sda";
    # Disque virtuel des tests (vmWithDisko, diskoImages) : 2G par défaut, < swap.
    imageSize = "16G";
    content = {
      type = "gpt";
      partitions = {
        boot = {
          size = "1M";
          type = "EF02";
        };
        swap = {
          size = "4G";
          # Clé aléatoire à chaque boot, pas d'hibernation ici.
          content = {
            type = "swap";
            randomEncryption = true;
          };
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
