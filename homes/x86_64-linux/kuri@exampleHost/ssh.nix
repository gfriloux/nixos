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
    settings = {
      "arthur.home" = {
        HostName = "192.168.0.153";
        User = "arthur";
      };
      "baptiste.home" = {
        HostName = "192.168.0.211";
        User = "baptiste";
      };
      "rogueleader.home" = {
        HostName = "192.168.0.10";
        User = "guillaume";
        IdentityFile = config.sops.secrets."ssh/keys/root@rogueleader".path;
      };
      "clochette.friloux.me" = {
        HostName = "clochette";
        User = "guillaume";
        IdentityFile = config.sops.secrets."ssh/keys/guillaume@clochette".path;
      };
      "irc.friloux.me" = {
        HostName = "clochette";
        User = "weechat";
        IdentityFile = config.sops.secrets."ssh/keys/weechat@clochette".path;
      };
      "storage2.friloux.me" = {
        User = "kuri";
        IdentityFile = config.sops.secrets."ssh/keys/kuri@storage2".path;
      };
      "github.com" = {
        User = "git";
        IdentityFile = config.sops.secrets."ssh/keys/github".path;
      };
    };
  };
}
