{
  pkgs,
  config,
  ...
}:
# Using borg:
# List backups:
#   BORG_PASSPHRASE=$(cat /run/secrets/services/borg/passphrase) BORG_RSH="ssh -i /run/secrets/services/borg/key/private" borg list 'ssh://backup@friloux.me/~/clochette.friloux.me'
{
  sops = {
    secrets = {
      "services/borg/passphrase" = {};
      "services/borg/key/private" = {};
    };
  };

  programs.ssh.knownHostsFiles = [
    (pkgs.writeText "friloux.me" ''
      storage2.friloux.me ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOKThAXm8UnDOFly/7CmT99HODn4W0o3bOYJHGXcAhOO
    '')
  ];

  services.borgbackup.jobs.remote = {
    paths = [
      "/srv/docker/traefik"
      "/srv/docker/crowdsec.clochette.friloux.me"
      "/srv/docker/crowdsec-manager"
      "/srv/docker/photos.friloux.me"
      "/home/weechat/.config/weechat"
    ];
    repo = "ssh://backup@storage2.friloux.me/~/clochette.friloux.me";

    encryption.mode = "repokey-blake2";
    encryption.passCommand = "cat ${config.sops.secrets."services/borg/passphrase".path}";
    compression = "auto,zstd";

    startAt = "daily";

    environment.BORG_RSH = "ssh -i ${config.sops.secrets."services/borg/key/private".path}";

    postHook = ''
      NTFY_TOPIC=$(cat ${config.sops.secrets."services/ntfy/topic".path})
      ${pkgs.curl}/bin/curl -s \
        -H "Title: [clochette] Backup réussi" \
        -d "Backup Borg du $(date +%Y-%m-%d) terminé avec succès" \
        "https://ntfy.sh/$NTFY_TOPIC"
    '';
  };

  systemd.services.borgbackup-check = {
    description = "Vérification d'intégrité Borg";
    unitConfig.OnFailure = "notify-failure@%n.service";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "borgbackup-check" ''
        export BORG_PASSPHRASE=$(cat ${config.sops.secrets."services/borg/passphrase".path})
        export BORG_RSH="ssh -i ${config.sops.secrets."services/borg/key/private".path}"
        ${pkgs.borgbackup}/bin/borg check --verify-data \
          'ssh://backup@storage2.friloux.me/~/clochette.friloux.me'
        NTFY_TOPIC=$(cat ${config.sops.secrets."services/ntfy/topic".path})
        ${pkgs.curl}/bin/curl -s \
          -H "Title: [clochette] Intégrité Borg OK" \
          -d "Vérification hebdomadaire des données Borg réussie" \
          "https://ntfy.sh/$NTFY_TOPIC"
      '';
    };
  };

  systemd.timers.borgbackup-check = {
    description = "Timer vérification hebdomadaire Borg";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "weekly";
      Persistent = true;
    };
  };
}
