{ system, lib, pkgs, config, ... }:

# Using borg:
# List backups:
#   BORG_PASSPHRASE=$(cat /run/secrets/services/borg/passphrase) BORG_RSH="ssh -i /run/secrets/services/borg/key/private" borg list 'ssh://backup@friloux.me/~/clochette.friloux.me'
{
  programs.ssh.knownHostsFiles = [
  	(pkgs.writeText "friloux.me" ''
  	  friloux.me ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOKThAXm8UnDOFly/7CmT99HODn4W0o3bOYJHGXcAhOO
  	'')
  ];

  services.borgbackup.jobs.remote = {
    paths = [
      "/srv/docker/traefik"
      "/srv/docker/docs.friloux.me"
      "/home/weechat/.config/weechat"
    ];
    repo = "ssh://backup@friloux.me/~/clochette.friloux.me";

    encryption.mode = "repokey-blake2";
    encryption.passCommand = "cat ${config.sops.secrets."services/borg/passphrase".path}";
    compression = "auto,zstd";

    startAt = "daily";

    environment.BORG_RSH = "ssh -i ${config.sops.secrets."services/borg/key/private".path}";
  };
}
