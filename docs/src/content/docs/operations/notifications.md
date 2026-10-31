---
title: "Failure notifications"
description: STC's docker-notify relic, health watch timers, ntfy.sh alerts.
---

STC relic `stc.relics.docker.notify`, the same on clochette, RogueLeader and skitarii.

## Flow

1. Container turns `unhealthy`.
2. Timer `stc-docker-health-watch@<name>` (every 30 s, first run 240 s after boot) sees it and runs `docker kill`.
3. systemd restarts it (`Restart = "on-failure"`, `RestartSec = 30s`).
4. 3 failures in 300 s (`StartLimitBurst`): the unit goes `failed` and **stays down**.
5. `OnFailure = stc-notify-failure@%p.service` runs `notifyCommand`: ntfy.sh push.

## Watch a container

```nix
extraOptions = inputs.stc.lib.docker.mkHealthCheck {
  cmd = "curl -fs http://localhost/health";
  startPeriod = "30s";  # optional, default 30s
};
labels = {
  # ... other labels ...
  "stc.docker/health-watch" = "true";  # last
};
```

The build fails if a watched container has no health check. If the image has its own `HEALTHCHECK`, add `"stc.docker/health-cmd-in-image" = "true";` instead of `mkHealthCheck`.

:::caution
Do not declare `OnFailure`, `Restart`, `StartLimitBurst` or the timers in `docker-*.nix`: the relic generates them. Extra `after`/`requires` are fine (NixOS merges).
:::

`stc-notify-failure@` also works as `OnFailure` for non-Docker units (borg check in `backup.nix`).

## notifyCommand

In each host's `default.nix`. It gets `STC_NOTIFY_SERVICE` and `STC_NOTIFY_HOSTNAME`; the ntfy topic is the sops secret `services/ntfy/topic`.

```nix
stc.relics.docker.notify = {
  enable = true;
  notifyCommand = ''
    ${pkgs.curl}/bin/curl -s \
      -H "Title: [$STC_NOTIFY_HOSTNAME] $STC_NOTIFY_SERVICE en défaut" \
      -d "$STC_NOTIFY_SERVICE est passé en état failed" \
      "https://ntfy.sh/$(cat ${config.sops.secrets."services/ntfy/topic".path})"
  '';
};
```

skitarii uses `curl -4 -sS --fail`: ntfy.sh rate-limits IPv6 per /64, shared between OVH customers.

## Check

```bash
systemctl list-timers | grep health-watch
systemctl start stc-docker-health-watch@immich-server   # manual run
```
