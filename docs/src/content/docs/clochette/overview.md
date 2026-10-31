---
title: clochette — The VPS-Shrine
description: Scaleway VPS hosting Immich, published through the pangolin gateway, with Docker-based bound daemons.
---

Behold clochette — the VPS-shrine exposed to the noosphere, where bound daemons serve personal domains across the network frontier.

## Bound Daemons & Services

| Daemon | Domain | Role |
|---|---|---|
| newt | — | Outbound tunnel to the pangolin gateway on skitarii |
| immich-server | photos.friloux.me | Photo gallery (self-hosted) |
| immich-postgres | — | PostgreSQL for Immich |
| immich-redis | — | Redis cache for Immich |

## Public Exposure

`photos.friloux.me` is a CNAME to `skitarii.friloux.me`: the pangolin gateway
publishes it, and `newt` carries the traffic through an outbound tunnel to
`immich-server` on the `web` network (created by `docker-newt.nix`). TLS,
crowdsec and the certificates live on skitarii (see
[The Gate](../skitarii/gateway.md)). clochette runs no traefik and no crowdsec
and opens no web port; SSH is reachable over Tailscale only.

No pangolin SSO on this resource: the Immich mobile app could not get through
it. Immich has no login throttle of its own, so skitarii's crowdsec covers it:
the `LePresidente/http-generic-401-bf` scenario bans bursts of `POST` answered
with 401.

## Network

Static IPv4 (`51.159.34.135/24`) in `network.nix`. IPv6 comes from Scaleway's
router advertisements (SLAAC): `2001:bc8:6005:1c:208:a2ff:fe0c:6ca2`, the
EUI-64 address published as `clochette.friloux.me`'s AAAA.

Temporary (privacy) addresses are disabled (`networking.tempAddresses`):
Scaleway only lets the EUI-64 address out, so anything leaving from a
temporary address was lost — inbound IPv6 worked, outbound did not (#108).

IPv6 visitors used to reach clochette's traefik through `docker-proxy`, which
logged the Docker gateway instead of the visitor, so crowdsec could not ban
them. Solved by the move behind the pangolin gateway: traffic now enters
through skitarii, whose traefik sees the real visitor, IPv4 or IPv6.

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
├── photos.friloux.me/
│   ├── upload/       # Immich photos
│   └── db/           # PostgreSQL data
```

`traefik/`, `crowdsec.clochette.friloux.me/` and `crowdsec-manager/` remain on
disk from the old stack: nothing uses them and Borg no longer backs them up.

## The Archive — Backup

Daily Borg backup to `ssh://backup@storage2.friloux.me/~/clochette.friloux.me`.

Backed-up paths: `/srv/docker/photos.friloux.me` (minus the live `db/`),
`/home/weechat/.config/weechat`.

:::note[Marginalia]
Immich's live PostgreSQL datadir (`photos.friloux.me/db`) is excluded from Borg.
The database is backed up through Immich's nightly dump in `upload/backups/`:
see [Rite of Restoration](../operations/restore.md#immich-clochette).
:::
