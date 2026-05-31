---
title: RogueLeader — The Home-Shrine
description: Domestic dedicated server with Borg, Mealie, and Uptime Kuma on the local network.
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
| `borg-ui` | Borg backup web interface |
| `mealie` | Recipe manager |
| `uptime-kuma` | External availability monitoring |

## Archive & Backup

Configured with borgbackup toward `storage2.friloux.me` (same pattern as clochette).

## Important Notes

- sops derives the age key from `/etc/ssh/ssh_host_ed25519_key` (like clochette)
- After reinstall: update `.sops.yaml` with the new age public key
  (see [Reliquary Backup & Restoration](../operations/secrets-backup.md))
- Deploy from exampleHost: `just install_rogueleader`
- Home Manager: `just home_rogueleader`
