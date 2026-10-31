---
title: RogueLeader — The Home-Shrine
description: Domestic dedicated server with Borg, Mealie, Uptime Kuma, Papra, and BookStack (public via the pangolin gateway).
---

Behold RogueLeader — the home-shrine, tending the domestic sanctuary on the local network frontier at `192.168.0.10`.

## Configuration

| Parameter | Value |
|---|---|
| Role | Domestic internal server |
| Local network | `rogueleader.home` (192.168.0.10) |
| OS | NixOS 25.11 |
| Storage | `/dev/sda`, ext4, GPT (via disko) |
| sops | Age key derived from SSH host key |
| stateVersion | `25.11` |

## Bound Daemons

| Daemon | Role |
|---|---|
| `newt` | Outbound tunnel to the pangolin gateway on skitarii |
| `borg-ui` | Borg backup web interface |
| `mealie` | Recipe manager |
| `uptime-kuma` | External availability monitoring |
| `papra` | Document management (docs.friloux.me) |
| `wow-cp-bookstack` | BookStack wiki (wow-cp.friloux.me) |
| `wow-cp-mariadb` | MariaDB for BookStack |
| `wow-cp-mysqldump` | SQL backup cron |

## Public Exposure

Every web daemon (mealie, borg-ui, uptime-kuma, papra, BookStack) is published
by the pangolin gateway on skitarii: each name is a CNAME to
`skitarii.friloux.me`, and `newt` carries the traffic through an outbound tunnel
to the containers on the `web` network. TLS, crowdsec and the certificates live
on skitarii (see [The Gate](../skitarii/gateway.md)). RogueLeader runs no
traefik and no crowdsec, opens no web port, and needs no port-forward on the
box.

## Archive & Backup

Configured with borgbackup toward `storage2.friloux.me` (same pattern as clochette).
Papra data (`/srv/docker/docs.friloux.me`) is included in the backup set.

## Important Notes

- sops derives the age key from `/etc/ssh/ssh_host_ed25519_key` (like clochette)
- After reinstall: update `.sops.yaml` with the new age public key
  (see [Reliquary Backup & Restoration](../operations/secrets-backup.md))
- Deploy from exampleHost: `just install_rogueleader`
- Home Manager: `just home_rogueleader`
