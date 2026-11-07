---
title: "Monitoring"
description: What watches what, and the commands to check by hand.
---

| What | By | Alert |
|---|---|---|
| Containers (healthcheck) | `stc-docker-health-watch@`, every 30 s: `unhealthy` → `docker kill` → systemd restart | ntfy, see [Failure notifications](/nixos/operations/notifications/) |
| Failed units | `stc-notify-failure@` (`OnFailure`) | ntfy |
| Borg | daily job (`postHook`) + weekly `borgbackup-check` (`--verify-data`), on clochette, skitarii, RogueLeader | ntfy on every run, success or failure |
| A scheduled job that stops succeeding | STC `heartbeat` relic: ping on success only → Uptime Kuma push monitor | ntfy, once the window passes without a ping |
| Web services from outside | Uptime Kuma on RogueLeader, page `status.friloux.me` | ntfy |
| pangolin nodes and resources | pangolin alert rules | ntfy, see [Gateway](/nixos/skitarii/gateway/) |

Uptime Kuma runs at home: if skitarii goes down, the public page goes down, alerts keep coming.

## Silence (#87)

A job that stops running fails nothing and notifies nothing. Each watched unit
pings a Kuma push monitor when it succeeds; Kuma alerts when the pings stop.

| Host | Unit | Window | Secret |
|---|---|---|---|
| clochette, skitarii, RogueLeader | `borgbackup-job-remote` | 36 h | `services/kuma/borg` |
| clochette, skitarii, RogueLeader | `borgbackup-check` | 8 days | `services/kuma/borg-check` |
| RogueLeader | `wow-cp-dump-age` (05:30, a dump younger than 26 h) | 36 h | `services/kuma/wow-cp-dumps` |

```bash
journalctl -u stc-heartbeat-borgbackup-job-remote -n 5   # "no ping" = the run did not succeed
```

New monitor: Push type in Kuma, 0 retries, its URL in the host's sops file,
then `stc.relics.heartbeat.units.<unit>.urlFile` next to the job.

Not covered:

- RogueLeader down: Kuma goes down with it, nobody alerts.
- skitarii down: pings reach Kuma through the gateway, so every push monitor
  alerts after its window.
- exampleHost: off most days, silence is normal there.

## Containers

```bash
docker ps --format "table {{.Names}}\t{{.Status}}"
docker inspect --format '{{json .State.Health}}' immich-server   # status + output of the last checks
journalctl -u immich-server --since "1 hour ago"
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
