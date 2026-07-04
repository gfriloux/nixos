---
title: RogueLeader — The Home-Shrine
description: Domestic dedicated server with Borg, Mealie, Uptime Kuma, Papra, and BookStack (public via Traefik).
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
| `traefik` | Reverse proxy + TLS (Let's Encrypt) |
| `crowdsec` | WAF / DDoS guard |
| `borg-ui` | Borg backup web interface |
| `mealie` | Recipe manager |
| `uptime-kuma` | External availability monitoring |
| `papra` | Document management (docs.friloux.me) |
| `wow-cp-bookstack` | BookStack wiki (wow-cp.friloux.me) |
| `wow-cp-mariadb` | MariaDB for BookStack |
| `wow-cp-mysqldump` | SQL backup cron |

## Public Exposure

Papra (`docs.friloux.me`) and BookStack (`wow-cp.friloux.me`) are served to the
noosphere through Traefik + CrowdSec, exactly like on clochette. Since RogueLeader
sits on the local network, the box port-forwards 80/443 to `192.168.0.10`; Let's
Encrypt certificates are issued via the TLS-ALPN-01 challenge on port 443. The
remaining daemons stay internal.

## Archive & Backup

Configured with borgbackup toward `storage2.friloux.me` (same pattern as clochette).
Papra data (`/srv/docker/docs.friloux.me`) is included in the backup set.

## Important Notes

- sops derives the age key from `/etc/ssh/ssh_host_ed25519_key` (like clochette)
- After reinstall: update `.sops.yaml` with the new age public key
  (see [Reliquary Backup & Restoration](../operations/secrets-backup.md))
- Deploy from exampleHost: `just install_rogueleader`
- Home Manager: `just home_rogueleader`
