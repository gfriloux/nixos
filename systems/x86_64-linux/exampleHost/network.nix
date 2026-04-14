{ config, lib, ... }:

  let
    cfg = config.zfs-root.networking;
    inherit (lib) types mkOption;
  in {
  	options.zfs-root.networking = {
  	  hostName = mkOption {
  	    description = "The name of the machine.  Used by nix flake.";
  	    type = types.str;
  	    default = "exampleHost";
  	  };
  	  timeZone = mkOption {
  	    type = types.str;
  	    default = "Etc/UTC";
  	  };
  	  hostId = mkOption {
  	    description = "Set host id";
  	    type = types.str;
  	  };
  	};
  	config = {
  	  time.timeZone = cfg.timeZone;
  	  networking = {
  	    firewall.enable = false;
  	    hostName = cfg.hostName;
  	    networkmanager.enable = true;
  	    hostId = cfg.hostId;
  	  };
  	};
  }
