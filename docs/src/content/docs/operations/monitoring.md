---
title: "Monitoring"
description: What watches what, and the commands to check by hand.
---

| What | By | Alert |
|---|---|---|
| Containers (healthcheck) | `stc-docker-health-watch@`, every 30 s: `unhealthy` → `docker kill` → systemd restart | ntfy, see [Failure notifications](/nixos/operations/notifications/) |
| Failed units | `stc-notify-failure@` (`OnFailure`) | ntfy |
| Borg | daily job (`postHook`) + weekly `borgbackup-check` (`--verify-data`), on clochette, skitarii, RogueLeader | ntfy on every run, success or failure |
| Web services from outside | Uptime Kuma on RogueLeader, page `status.friloux.me` | ntfy |
| pangolin nodes and resources | pangolin alert rules | ntfy, see [Gateway](/nixos/skitarii/gateway/) |

Uptime Kuma runs at home: if skitarii goes down, the public page goes down, alerts keep coming.

## Containers

```bash
docker ps --format "table {{.Names}}\t{{.Status}}"
docker inspect --format '{{json .State.Health}}' immich-server   # status + output of the last checks
journalctl -u docker-immich-server --since "1 hour ago"
systemctl list-timers | grep health-watch
```

Healthchecks run inside the container: a `curl localhost:<port>` from the host
fails, no port is published. Test with `docker exec <container> <cmd>`.

## Borg

```bash
systemctl status borgbackup-job-remote
journalctl -u borgbackup-job-remote --since today
sudo systemctl start borgbackup-check      # integrity check by hand
```

List archives: [Restore from Borg](/nixos/operations/restore/).

## Web logs

Everything goes through skitarii's traefik:

```bash
sudo tail -f /srv/docker/pangolin.friloux.me/traefik-logs/access.log
```
