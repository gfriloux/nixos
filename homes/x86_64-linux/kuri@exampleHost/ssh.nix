{config, ...}: {
  sops = {
    secrets = {
      "ssh/keys/guillaume@clochette" = {};
      "ssh/keys/weechat@clochette" = {};
      "ssh/keys/guillaume@skitarii" = {};
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

  # yubikey-touch-detector (stc relic) proxies the agent: it renames its
  # socket to ssh-agent.original and listens on ssh-agent itself. Restarted
  # alone at a switch, ssh-agent then failed with "Address already in use"
  # and ssh-add hung. Tie the two: the detector stops before the agent and
  # comes back after it (#134).
  systemd.user.services.yubikey-touch-detector.Unit = {
    After = ["ssh-agent.service"];
    PartOf = ["ssh-agent.service"];
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
      # One failed key costs an hour of ban on skitarii (PerSourcePenalties):
      # offer only this key, never everything the agent holds.
      "skitarii.friloux.me" = {
        HostName = "skitarii";
        User = "guillaume";
        IdentityFile = config.sops.secrets."ssh/keys/guillaume@skitarii".path;
        IdentitiesOnly = true;
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
