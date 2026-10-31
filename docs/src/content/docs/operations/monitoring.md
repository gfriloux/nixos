---
title: The Astropath & Observability — Monitoring Services
description: Health checks, container status, Borg backups, and log inspection.
---

Overview of surveillance mechanisms across the Forge.

## Failure Notifications (ntfy.sh)

On every host that runs containers (clochette, RogueLeader, skitarii), daemons
with the label `stc.docker/health-watch = "true"` are automatically watched by
STC's `relics-docker-notify` relic. See [The Astropath](../clochette/notifications.md).

Two mechanisms:

| Mechanism | Trigger | Action |
|---|---|---|
| `stc-notify-failure@` | systemd service → `failed` state | `notifyCommand` → ntfy.sh notification |
| `stc-docker-health-watch@` (30s timer) | `docker inspect` returns `unhealthy` | `docker kill` → systemd restart → ntfy.sh |

Notifications arrive on the topic in `services/ntfy/topic`. The examples below are taken on clochette.

## Check Container Status

```bash
# Quick view — all containers
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.RunningFor}}"

# Detailed health of a container
docker inspect --format='{{.Name}} : {{.State.Health.Status}}' immich-server

# Health of all watched daemons
for c in newt immich-server immich-postgres immich-redis; do
  echo "$c : $(docker inspect --format='{{.State.Health.Status}}' $c 2>/dev/null || echo 'not found')"
done
```

## Health Check Endpoints

| Service | Test Command |
|---|---|
| newt | `docker exec newt test -f /tmp/healthy` |
| immich | `curl -s http://localhost:2283/api/server/ping` |
| postgres | `docker exec immich-postgres pg_isready -U immich -d immich` |
| redis | `docker exec immich-redis redis-cli ping` |

## Active systemd Timers

```bash
# List all timers and next trigger
systemctl list-timers --all

# Specific timers to watch
systemctl list-timers | grep -E "borg|health-watch|logrotate"
```

## Borg Backup

```bash
# Status of last backup
systemctl status borgbackup-job-remote

# Journal of last backup
journalctl -u borgbackup-job-remote --since today

# List available archives
BORG_PASSPHRASE=$(cat /run/secrets/services/borg/passphrase) \
BORG_RSH="ssh -i /run/secrets/services/borg/key/private" \
borg list ssh://backup@storage2.friloux.me/~/clochette.friloux.me

# Manual integrity check
systemctl start borgbackup-check
```

## Logs

```bash
# Docker service logs via journald
journalctl -u docker-newt -f
journalctl -u docker-immich-server --since "1 hour ago"

# Web access logs live on skitarii, whose traefik fronts the gateway
sudo tail -f /srv/docker/pangolin.friloux.me/traefik-logs/access.log

# Logrotate — verify last run
journalctl -u logrotate --since today
```

## Uptime Kuma

Uptime Kuma runs on RogueLeader (`uptime-kuma` container) and serves the status
page at `status.friloux.me`, published through the pangolin gateway. If skitarii
goes down the public page goes with it, but Uptime Kuma keeps running at home
and keeps alerting through ntfy.

See [RogueLeader](../rogueleader/overview.md).
