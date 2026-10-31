---
title: "RogueLeader"
description: Home server. BookStack, Mealie, Papra, Uptime Kuma, Borg UI, published through the pangolin gateway.
sidebar:
  order: 1
  label: "Overview"
---

| Container | Domain | Role |
|---|---|---|
| `newt` | | Outbound tunnel to the [gateway](/nixos/skitarii/gateway/) |
| `wow-cp-bookstack` | `wow-cp.friloux.me` | Wiki ([BookStack](/nixos/rogueleader/bookstack/)) |
| `wow-cp-mariadb` | | MariaDB for BookStack |
| `wow-cp-mysqldump` | | Nightly SQL dump |
| `papra` | `docs.friloux.me` | Documents ([Papra](/nixos/rogueleader/papra/)) |
| `mealie` | `cuisine.friloux.me` | Recipes |
| `uptime-kuma` | `status.friloux.me` | Status page |
| `borg-ui` | `borg-ui.friloux.me` | Borg web UI |

Every domain is a CNAME to `skitarii.friloux.me`. No traefik, no crowdsec, no open port, no port-forward on the box.

## Host

| | |
|---|---|
| Network | `rogueleader.home` (`192.168.0.10`), LAN only |
| Disk | `/dev/sda`, GPT via disko: 1M BIOS boot, 4G swap, ext4 `/`. GRUB, BIOS |
| sops | age key from `/etc/ssh/ssh_host_ed25519_key`. After a reinstall: new key in `.sops.yaml`, see [Age key backup](/nixos/operations/secrets-backup/) |
| stateVersion | `25.11` |

## Deploy

```bash
just install_rogueleader   # system
just home_rogueleader      # Home Manager only
```

## Backup

Borg to `ssh://backup@storage2.friloux.me/~/rogueleader.friloux.me`, `backup.nix`.

| Path | Note |
|---|---|
| `/srv/docker/wow-cp.friloux.me` | live `db/` excluded, the SQL dump covers it |
| `/srv/docker/docs.friloux.me` | live SQLite excluded |
| `/srv/docker/status.friloux.me` | live SQLite excluded |
| `/srv/docker/cuisine.home.friloux.me` | live SQLite excluded |
| `/srv/docker/sqlite-snapshots` | copies of the three SQLite databases, taken before `borg create` |
