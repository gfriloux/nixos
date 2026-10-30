{
  pkgs,
  config,
  ...
}:
# Using borg:
# List backups:
#   BORG_PASSPHRASE=$(cat /run/secrets/services/borg/passphrase) BORG_RSH="ssh -i /run/secrets/services/borg/key/private" borg list 'ssh://backup@storage2.friloux.me/~/skitarii.friloux.me'
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
      "/srv/docker/pangolin.friloux.me"
      "/srv/docker/crowdsec.skitarii.friloux.me"
      "/srv/docker/crowdsec-manager"
      "/srv/docker/sqlite-snapshots"
    ];
    # Live SQLite databases (-wal/-shm included): restore from
    # sqlite-snapshots/, taken by preHook below. borg fails the job when one
    # changes under it (kuma.db-wal on RogueLeader, 2026-10-25).
    # traefik's access log has nothing to restore.
    exclude = [
      "/srv/docker/pangolin.friloux.me/config/db/db.sqlite*"
      "/srv/docker/pangolin.friloux.me/traefik-logs"
      "/srv/docker/crowdsec.skitarii.friloux.me/data/crowdsec.db*"
      "/srv/docker/crowdsec-manager/data/settings.db*"
      "/srv/docker/crowdsec-manager/data/history.db*"
    ];
    # sqlite3's .backup goes through SQLite's backup API: a consistent copy of
    # a database that is being written to, WAL included. set -e in the job
    # script turns a failed snapshot into a failed (and notified) backup.
    # The job runs with ProtectSystem=strict: it writes the snapshots, and
    # SQLite needs write access next to a WAL database (-shm) even to read it.
    readWritePaths = [
      "/srv/docker/sqlite-snapshots"
      "/srv/docker/pangolin.friloux.me/config/db"
      "/srv/docker/crowdsec.skitarii.friloux.me/data"
      "/srv/docker/crowdsec-manager/data"
    ];
    preHook = ''
      snapshots=/srv/docker/sqlite-snapshots
      for db in \
        pangolin:/srv/docker/pangolin.friloux.me/config/db/db.sqlite \
        crowdsec:/srv/docker/crowdsec.skitarii.friloux.me/data/crowdsec.db \
        crowdsec-manager-settings:/srv/docker/crowdsec-manager/data/settings.db \
        crowdsec-manager-history:/srv/docker/crowdsec-manager/data/history.db; do
        ${pkgs.sqlite}/bin/sqlite3 -cmd ".timeout 30000" "''${db#*:}" \
          ".backup '$snapshots/''${db%%:*}.db'"
      done
    '';
    repo = "ssh://backup@storage2.friloux.me/~/skitarii.friloux.me";

    encryption.mode = "repokey-blake2";
    encryption.passCommand = "cat ${config.sops.secrets."services/borg/passphrase".path}";
    compression = "auto,zstd";

    startAt = "*-*-* 04:00:00";

    environment.BORG_RSH = "ssh -i ${config.sops.secrets."services/borg/key/private".path}";

    # postHook runs on every exit, failures included: report $exitStatus
    # instead of always claiming success. -o /dev/null keeps ntfy's reply,
    # which echoes the topic, out of the journal.
    # -4 : ntfy.sh limite l'IPv6 par /64, et celui de skitarii est partagé
    # entre VPS OVH ; le quota anonyme y est épuisé par les voisins (429).
    # --fail : sans lui, un 429 sortait en 0, sans trace. Avec set -e, une
    # notification refusée fait échouer le job, même si l'archive est faite.
    postHook = ''
      NTFY_TOPIC=$(cat ${config.sops.secrets."services/ntfy/topic".path})
      if [ "$exitStatus" -eq 0 ]; then
        title="[skitarii] Backup réussi"
        msg="Backup Borg du $(date +%Y-%m-%d) terminé avec succès"
      else
        title="[skitarii] Backup ÉCHOUÉ"
        msg="Backup Borg du $(date +%Y-%m-%d) en échec (code $exitStatus) : journalctl -u borgbackup-job-remote"
      fi
      ${pkgs.curl}/bin/curl -4 -sS --fail -o /dev/null \
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
            'ssh://backup@storage2.friloux.me/~/skitarii.friloux.me'
          NTFY_TOPIC=$(cat ${config.sops.secrets."services/ntfy/topic".path})
          # -4 --fail : voir le postHook du job.
          ${pkgs.curl}/bin/curl -4 -sS --fail -o /dev/null \
            -H "Title: [skitarii] Intégrité Borg OK" \
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
