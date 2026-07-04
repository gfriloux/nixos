---
title: clochette — The VPS-Shrine
description: Scaleway VPS hosting personal web services behind Traefik, with Docker-based bound daemons.
---

Behold clochette — the VPS-shrine exposed to the noosphere, where bound daemons serve personal domains across the network frontier.

## Bound Daemons & Services

| Daemon | Domain | Role |
|---|---|---|
| traefik | — | Reverse proxy, TLS (Let's Encrypt) |
| crowdsec | — | WAF, DDoS guard, Traefik plugin |
| papra | docs.friloux.me | Document management |
| wow-cp-bookstack | wow-cp.friloux.me | Wiki |
| wow-cp-mariadb | — | MariaDB for BookStack |
| wow-cp-mysqldump | — | SQL backup cron |
| immich-server | photos.friloux.me | Photo gallery (self-hosted) |
| immich-postgres | — | PostgreSQL for Immich |
| immich-redis | — | Redis cache for Immich |
| crowdsec-manager | :3000 | CrowdSec management UI |

## The Pilgrims — System Users

| User | Shell | Role |
|---|---|---|
| `guillaume` | fish | System admin, wheel+docker groups |
| `weechat` | fish | Persistent IRC session via zellij |

SSH accepts ed25519 and sk-ssh-ed25519 (YubiKey) keys.

## Data Vaults

All persistent bound daemon data resides beneath `/srv/docker/`:

```text
/srv/docker/
├── traefik/
│   ├── conf/         # traefik.yml (Nix symlink), traefik_dynamic.yml (sops)
│   ├── acme.json     # Let's Encrypt certificates
│   └── logs/         # Access logs (rotated daily)
├── docs.friloux.me/  # Papra data
├── wow-cp.friloux.me/
│   ├── data/         # BookStack files
│   ├── db/           # MariaDB data
│   └── dumps/        # mysqldump SQL backups
├── photos.friloux.me/
│   ├── upload/       # Immich photos
│   └── db/           # PostgreSQL data
├── crowdsec.clochette.friloux.me/  # CrowdSec config and data
└── crowdsec-manager/ # crowdsec-manager config and DB
```

## The Archive — Backup

Daily Borg backup to `ssh://backup@storage2.friloux.me/~/clochette.friloux.me`.

Backed-up paths: `/srv/docker/traefik`, `docs.friloux.me`, `wow-cp.friloux.me`,
`crowdsec*.`, `photos.friloux.me/upload`, `/home/weechat/.config/weechat`.

:::note[Marginalia]
Immich PostgreSQL data (`photos.friloux.me/db`) is included in Borg backup.
For clean Immich restoration, consider a pg_dump before Borg restore.
:::
