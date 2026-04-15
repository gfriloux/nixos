{config, ...}: {
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    matchBlocks = {
      "*" = {
        controlMaster = "auto";
        controlPath = "~/.ssh/sockets/%r@%h:%p";
        controlPersist = "60m";
        setEnv = {
          TERM = "xterm-256color";
        };
      };
      "arthur.home" = {
        hostname = "192.168.0.153";
        user = "arthur";
      };
      "baptiste.home" = {
        hostname = "192.168.0.211";
        user = "baptiste";
      };
      "rogueleader.home" = {
        hostname = "192.168.0.10";
        user = "root";
        identityFile = "~/.ssh/id_ed25519";
      };
      "clochette.friloux.me" = {
        user = "guillaume";
        identityFile = config.sops.secrets."ssh/keys/guillaume@clochette".path;
      };
      "irc.friloux.me" = {
        user = "weechat";
        identityFile = config.sops.secrets."ssh/keys/weechat@clochette".path;
      };
      "storage2.friloux.me" = {
        user = "kuri";
        identityFile = "~/.ssh/id_ed25519";
      };
    };
  };
}
