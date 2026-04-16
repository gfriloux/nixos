{pkgs, ...}: {
  services = {
    udev.packages = [pkgs.yubikey-personalization];
    pcscd.enable = true;
    displayManager.sddm.enable = true;
    displayManager.sddm.wayland.enable = true;
    desktopManager.plasma6.enable = true;
    flatpak.enable = true;
    pulseaudio.enable = false;
    tumbler.enable = true; # Thumbnail support for images
    zfs = {
      autoScrub.enable = true;
      trim.enable = true;
    };
    zrepl = {
      enable = true;
      settings = {
        global = {};
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
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = true;
        PermitRootLogin = "no";
      };
    };
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      wireplumber.enable = true;
    };

    dbus.enable = true;
    gvfs.enable = true;

    xserver.enable = false;

    libinput.enable = true;
  };
}
