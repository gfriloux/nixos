---
title: The Astropath & Observability — Monitoring Services
description: Health checks, container status, Borg backups, and log inspection.
---

Overview of surveillance mechanisms across the Forge.

## Failure Notifications (ntfy.sh)

All daemons on clochette with the label `friloux.me/health-watch = "true"`
are automatically watched by the `notify-docker` pattern.

Two mechanisms:

| Mechanism | Trigger | Action |
|---|---|---|
| `notify-failure@` | systemd service → `failed` state | ntfy.sh notification |
| `docker-health-watch@` (30s timer) | `docker inspect` returns `unhealthy` | `docker kill` → systemd restart → ntfy.sh |

Notifications arrive on the topic in `services/ntfy/topic`.

## Check Container Status

```bash
# Quick view — all containers
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.RunningFor}}"

# Detailed health of a container
docker inspect --format='{{.Name}} : {{.State.Health.Status}}' traefik

# Health of all watched daemons
for c in traefik crowdsec wow-cp-bookstack wow-cp-mariadb immich-server immich-postgres; do
  echo "$c : $(docker inspect --format='{{.State.Health.Status}}' $c 2>/dev/null || echo 'not found')"
done
```

## Health Check Endpoints

| Service | Test Command |
|---|---|
| traefik | `curl -s http://127.0.0.1:8080/ping` |
| crowdsec | `curl -s http://localhost:8080/health` |
| bookstack | `curl -s http://localhost/status` |
| mariadb | `docker exec wow-cp-mariadb mysqladmin ping -h localhost --silent` |
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
journalctl -u docker-traefik -f
journalctl -u docker-wow-cp-bookstack --since "1 hour ago"

# Traefik application logs (rotated file)
tail -f /srv/docker/traefik/logs/traefik.log

# Logrotate — verify last run
journalctl -u logrotate --since today
```

## Uptime Kuma (Planned)

Uptime Kuma will be installed on a future NixOS shrine to provide
external monitoring independent of clochette.

See [Design & Prerequisites — RogueLeader](../rogueleader/planning.md).
