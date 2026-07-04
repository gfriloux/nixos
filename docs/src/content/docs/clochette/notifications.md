---
title: The Astropath — Container Failure Notifications
description: Automated health watch timers, failure detection, and ntfy.sh alerts.
---

The Astropath (`notify-docker`) heralds container omens automatically. When a bound daemon falls ill, the Astropath cries out.

## What Is Generated Automatically

For each container bearing the label `friloux.me/health-watch = "true"`, the module creates:

- A `systemd.services` block with `OnFailure`, `Restart = "on-failure"`, `RestartSec = 30s`, `StartLimitBurst = 3`
- A timer `docker-health-watch@<name>` running every 30 seconds
- The template service `docker-health-watch@<name>` that kills the container if `unhealthy`
- The template service `notify-failure@<name>` that sends an ntfy.sh notification

**Do not declare these manually in `docker-*.nix` files.**

## Adding Surveillance to a Container

Add the label to the container definition (last):

```nix
labels = {
  # ... other traefik labels ...
  "friloux.me/health-watch" = "true";
};
```

And ensure the container has a health check defined via `extraOptions`:

```nix
extraOptions = lib.kuri.docker.mkHealthCheck {
  cmd = "curl -fs http://localhost/health";
  startPeriod = "30s";  # optional
};
```

## Notification Flow

```text
Container → unhealthy
    └── docker-health-watch@ → docker kill <container>
            └── systemd detects death → restart
                    └── if StartLimitBurst reached → failed
                            └── notify-failure@ → ntfy.sh push
```

## Checking Surveillance Timers

```bash
systemctl list-timers | grep health-watch

# Trigger manually (test)
systemctl start docker-health-watch@traefik
```

## ntfy.sh Configuration

The topic is stored in `sops.secrets."services/ntfy/topic"`.
Notifications include the hostname and service name.
