{
  pkgs,
  config,
  ...
}:
# Using borg:
# List backups:
#   BORG_PASSPHRASE=$(cat /run/secrets/services/borg/passphrase) BORG_RSH="ssh -i /run/secrets/services/borg/key/private" borg list 'ssh://backup@storage2.friloux.me/~/rogueleader.friloux.me'
{
  sops.secrets = {
    "services/borg/passphrase" = {};
    "services/borg/key/private" = {};
  };

  programs.ssh.knownHostsFiles = [
    (pkgs.writeText "storage2.friloux.me" ''
      storage2.friloux.me ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOKThAXm8UnDOFly/7CmT99HODn4W0o3bOYJHGXcAhOO
    '')
  ];

  services.borgbackup.jobs.remote = {
    paths = [
      "/srv/docker/traefik"
      "/srv/docker/crowdsec.rogueleader.home"
      "/srv/docker/status.friloux.me"
      "/srv/docker/cuisine.home.friloux.me"
      "/srv/docker/docs.friloux.me"
      "/srv/docker/wow-cp.friloux.me"
    ];
    # wow-cp's live MariaDB datadir: a file-by-file copy of a running server
    # is not restorable. The consistent copy is dumps/ (wow-cp-mysqldump,
    # nightly, last 15 kept): restore from there, not from db/.
    exclude = ["/srv/docker/wow-cp.friloux.me/db"];
    repo = "ssh://backup@storage2.friloux.me/~/rogueleader.friloux.me";

    encryption.mode = "repokey-blake2";
    encryption.passCommand = "cat ${config.sops.secrets."services/borg/passphrase".path}";
    compression = "auto,zstd";

    # After wow-cp's dump, which runs at 03:00 UTC (04:00 or 05:00 here), so
    # each archive carries that night's dump instead of the previous day's.
    startAt = "*-*-* 06:00:00";

    environment.BORG_RSH = "ssh -i ${config.sops.secrets."services/borg/key/private".path}";

    postHook = ''
      NTFY_TOPIC=$(cat ${config.sops.secrets."services/ntfy/topic".path})
      ${pkgs.curl}/bin/curl -s \
        -H "Title: [RogueLeader] Backup réussi" \
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
          'ssh://backup@storage2.friloux.me/~/rogueleader.friloux.me'
        NTFY_TOPIC=$(cat ${config.sops.secrets."services/ntfy/topic".path})
        ${pkgs.curl}/bin/curl -s \
          -H "Title: [RogueLeader] Intégrité Borg OK" \
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
