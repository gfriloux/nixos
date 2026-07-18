{config, ...}: {
  sops = {
    secrets = {
      "ssh/keys/guillaume@clochette" = {};
      "ssh/keys/weechat@clochette" = {};
      "ssh/keys/kuri@storage2" = {};
      "ssh/keys/root@rogueleader" = {};
      "ssh/keys/github" = {};
    };
  };

  services = {
    ssh-agent = {
      enable = true;
    };
  };

  # Connection multiplexing (Host *) and enable/enableDefaultConfig come from
  # stc cogitator-enginseer. Only host-specific blocks remain here.
  programs.ssh = {
    matchBlocks = {
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
        user = "guillaume";
        identityFile = config.sops.secrets."ssh/keys/root@rogueleader".path;
      };
      "clochette.friloux.me" = {
        hostname = "clochette";
        user = "guillaume";
        identityFile = config.sops.secrets."ssh/keys/guillaume@clochette".path;
      };
      "irc.friloux.me" = {
        hostname = "clochette";
        user = "weechat";
        identityFile = config.sops.secrets."ssh/keys/weechat@clochette".path;
      };
      "storage2.friloux.me" = {
        user = "kuri";
        identityFile = config.sops.secrets."ssh/keys/kuri@storage2".path;
      };
      "github.com" = {
        user = "git";
        identityFile = config.sops.secrets."ssh/keys/github".path;
      };
    };
  };
}
