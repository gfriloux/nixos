---
title: The Astropath — Container Failure Notifications
description: STC's docker-notify relic — health watch timers, failure detection, and ntfy.sh alerts.
---

The Astropath heralds container omens automatically. When a bound daemon falls ill, the Astropath cries out.

The Astropath is STC's `relics-docker-notify` relic (`stc.relics.docker.notify`),
imported from the `stc` flake input. It works the same way on every host that
runs containers (clochette, RogueLeader, skitarii); this page uses clochette
for its examples.

## Enabling the Relic

Each host enables it in its `default.nix` and provides `notifyCommand`, the
shell snippet that delivers the alert. STC owns the wiring, not the transport:
the command receives `STC_NOTIFY_SERVICE` (the failed unit) and
`STC_NOTIFY_HOSTNAME` in its environment, and reads its own secrets.

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

On skitarii the call is `curl -4 -sS --fail`: ntfy.sh rate-limits IPv6 per
/64, and OVH shares that /64 between customers.

## What Is Generated Automatically

For each container bearing the label `stc.docker/health-watch = "true"`, the relic creates:

- On the container's unit: `OnFailure = stc-notify-failure@%p.service`, `Restart = "on-failure"`, `RestartSec = 30s`, `StartLimitBurst = 3` within `StartLimitIntervalSec = 300s`
- A timer `stc-docker-health-watch@<name>` running every 30 seconds (first run 240 s after boot)
- The template service `stc-docker-health-watch@<name>` that `docker kill`s the container if `docker inspect` reports `unhealthy`
- The template service `stc-notify-failure@<unit>` that runs `notifyCommand`

**Do not declare these manually in `docker-*.nix` files.** Container-specific
overrides (extra `after`/`requires`) can still go there; NixOS merges them.

`stc-notify-failure@` is also usable as `OnFailure` for non-Docker units: the
borg check in each host's `backup.nix` uses it.

## Adding Surveillance to a Container

Add the label to the container definition (last, after any other labels):

```nix
labels = {
  # ... other labels ...
  "stc.docker/health-watch" = "true";
};
```

And ensure the container has a health check defined via `extraOptions`:

```nix
extraOptions = inputs.stc.lib.docker.mkHealthCheck {
  cmd = "curl -fs http://localhost/health";
  startPeriod = "30s";  # optional, defaults to 30s
};
```

The relic refuses to build if a watched container has no health check it can
see. If the image already declares a `HEALTHCHECK` (invisible at evaluation
time), say so with a second label instead of `mkHealthCheck`:

```nix
labels = {
  "stc.docker/health-cmd-in-image" = "true";
  "stc.docker/health-watch" = "true";
};
```

## Notification Flow

```text
Container → unhealthy
    └── stc-docker-health-watch@ → docker kill <container>
            └── systemd detects death → restart
                    └── if StartLimitBurst reached → failed
                            └── stc-notify-failure@ → notifyCommand → ntfy.sh push
```

Once the start limit is reached, systemd stops restarting the container: it
stays down, and the notification is the only signal.

## Checking Surveillance Timers

```bash
systemctl list-timers | grep health-watch

# Trigger manually (test)
systemctl start stc-docker-health-watch@immich-server
```

## ntfy.sh Configuration

The topic is stored in `sops.secrets."services/ntfy/topic"`, declared in each
host's `default.nix`. The title carries the hostname and the failed unit.
