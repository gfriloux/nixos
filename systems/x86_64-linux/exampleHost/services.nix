{pkgs, ...}: {
  environment.systemPackages = [pkgs.catppuccin-sddm];

  virtualisation.docker = {
    enable = true;
    storageDriver = "zfs";
  };

  security.protectKernelImage = true;

  systemd.coredump.settings.Coredump = {
    Storage = "none";
    ProcessSizeMax = 0;
  };

  services = {
    flatpak.enable = true;
    zrepl = {
      enable = true;
      settings = {
        jobs = [
          {
            name = "storage2";
            type = "pull";
            root_fs = "rpool/backup/storage2";
            interval = "10m";
            connect = {
              type = "ssh+stdinserver";
              host = "storage2.retrohive.fr";
              user = "root";
              port = 22;
              identity_file = "/root/.ssh/id_ed25519";
            };
            recv = {placeholder = {encryption = "inherit";};};
            pruning = {
              keep_receiver = [
                {
                  type = "grid";
                  grid = "7x1d(keep=all) | 3x30d";
                  regex = "^zrepl_.*";
                }
              ];
              keep_sender = [
                {
                  type = "last_n";
                  count = 10;
                  regex = "^zrepl_.*";
                }
              ];
            };
          }
        ];
      };
    };
    tailscale.enable = true;
  };
}
