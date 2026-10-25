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
      "/srv/docker/sqlite-snapshots"
    ];
    # Live databases are not restorable from a file-by-file copy, and borg
    # fails the job when one changes under it (kuma.db-wal, 2026-10-25).
    # - wow-cp's MariaDB datadir: restore from dumps/ (wow-cp-mysqldump,
    #   nightly, last 15 kept), not from db/.
    # - SQLite (-wal/-shm included): restore from sqlite-snapshots/, taken by
    #   preHook below.
    exclude = [
      "/srv/docker/wow-cp.friloux.me/db"
      "/srv/docker/status.friloux.me/data/kuma.db*"
      "/srv/docker/docs.friloux.me/data/db/db.sqlite*"
      "/srv/docker/cuisine.home.friloux.me/data/mealie.db*"
    ];
    # sqlite3's .backup goes through SQLite's backup API: a consistent copy of
    # a database that is being written to, WAL included. set -e in the job
    # script turns a failed snapshot into a failed (and notified) backup.
    # The job runs with ProtectSystem=strict: it writes the snapshots, and
    # SQLite needs write access next to a WAL database (-shm) even to read it.
    readWritePaths = [
      "/srv/docker/sqlite-snapshots"
      "/srv/docker/status.friloux.me/data"
      "/srv/docker/docs.friloux.me/data/db"
      "/srv/docker/cuisine.home.friloux.me/data"
    ];
    preHook = ''
      snapshots=/srv/docker/sqlite-snapshots
      for db in \
        uptime-kuma:/srv/docker/status.friloux.me/data/kuma.db \
        papra:/srv/docker/docs.friloux.me/data/db/db.sqlite \
        mealie:/srv/docker/cuisine.home.friloux.me/data/mealie.db; do
        ${pkgs.sqlite}/bin/sqlite3 -cmd ".timeout 30000" "''${db#*:}" \
          ".backup '$snapshots/''${db%%:*}.db'"
      done
    '';
    repo = "ssh://backup@storage2.friloux.me/~/rogueleader.friloux.me";

    encryption.mode = "repokey-blake2";
    encryption.passCommand = "cat ${config.sops.secrets."services/borg/passphrase".path}";
    compression = "auto,zstd";

    # After wow-cp's dump, which runs at 03:00 UTC (04:00 or 05:00 here), so
    # each archive carries that night's dump instead of the previous day's.
    startAt = "*-*-* 06:00:00";

    environment.BORG_RSH = "ssh -i ${config.sops.secrets."services/borg/key/private".path}";

    # postHook runs on every exit, failures included: report $exitStatus
    # instead of always claiming success. -o /dev/null keeps ntfy's reply,
    # which echoes the topic, out of the journal.
    postHook = ''
      NTFY_TOPIC=$(cat ${config.sops.secrets."services/ntfy/topic".path})
      if [ "$exitStatus" -eq 0 ]; then
        title="[RogueLeader] Backup réussi"
        msg="Backup Borg du $(date +%Y-%m-%d) terminé avec succès"
      else
        title="[RogueLeader] Backup ÉCHOUÉ"
        msg="Backup Borg du $(date +%Y-%m-%d) en échec (code $exitStatus) : journalctl -u borgbackup-job-remote"
      fi
      ${pkgs.curl}/bin/curl -s -o /dev/null \
        -H "Title: $title" \
        -d "$msg" \
        "https://ntfy.sh/$NTFY_TOPIC"
    '';
  };

  systemd = {
    services.borgbackup-check = {
      description = "Vérification d'intégrité Borg";
      unitConfig.OnFailure = "stc-notify-failure@%p.service";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "borgbackup-check" ''
          export BORG_PASSPHRASE=$(cat ${config.sops.secrets."services/borg/passphrase".path})
          export BORG_RSH="ssh -i ${config.sops.secrets."services/borg/key/private".path}"
          ${pkgs.borgbackup}/bin/borg check --verify-data \
            'ssh://backup@storage2.friloux.me/~/rogueleader.friloux.me'
          NTFY_TOPIC=$(cat ${config.sops.secrets."services/ntfy/topic".path})
          ${pkgs.curl}/bin/curl -s -o /dev/null \
            -H "Title: [RogueLeader] Intégrité Borg OK" \
            -d "Vérification hebdomadaire des données Borg réussie" \
            "https://ntfy.sh/$NTFY_TOPIC"
        '';
      };
    };

    timers.borgbackup-check = {
      description = "Timer vérification hebdomadaire Borg";
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = "weekly";
        Persistent = true;
      };
    };

    # Must exist before the job starts, as one of its ReadWritePaths.
    tmpfiles.rules = [
      "d /srv/docker/sqlite-snapshots 0700 root root -"
    ];
  };
}
