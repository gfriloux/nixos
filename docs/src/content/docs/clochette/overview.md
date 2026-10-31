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
| immich-server | photos.friloux.me | Photo gallery (self-hosted) |
| immich-postgres | — | PostgreSQL for Immich |
| immich-redis | — | Redis cache for Immich |
| crowdsec-manager | :3000 | CrowdSec management UI |

## Network

Static IPv4 (`51.159.34.135/24`) in `network.nix`. IPv6 comes from Scaleway's
router advertisements (SLAAC): `2001:bc8:6005:1c:208:a2ff:fe0c:6ca2`, the
EUI-64 address published as `clochette.friloux.me`'s AAAA.

Temporary (privacy) addresses are disabled (`networking.tempAddresses`):
Scaleway only lets the EUI-64 address out, so anything leaving from a
temporary address was lost — inbound IPv6 worked, outbound did not (#108).

IPv6 visitors still reach traefik through `docker-proxy`, which logs the Docker
gateway (`172.19.0.1`) instead of the visitor: crowdsec cannot ban them. Left
as-is on purpose, the move of clochette's services behind the pangolin gateway
removes the problem.

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
├── photos.friloux.me/
│   ├── upload/       # Immich photos
│   └── db/           # PostgreSQL data
├── crowdsec.clochette.friloux.me/  # CrowdSec config and data
└── crowdsec-manager/ # crowdsec-manager config and DB
```

## The Archive — Backup

Daily Borg backup to `ssh://backup@storage2.friloux.me/~/clochette.friloux.me`.

Backed-up paths: `/srv/docker/traefik`,
`crowdsec*.`, `photos.friloux.me/upload`, `/home/weechat/.config/weechat`.

:::note[Marginalia]
Immich's live PostgreSQL datadir (`photos.friloux.me/db`) is excluded from Borg.
The database is backed up through Immich's nightly dump in `upload/backups/`:
see [Rite of Restoration](../operations/restore.md#immich-clochette).
:::
