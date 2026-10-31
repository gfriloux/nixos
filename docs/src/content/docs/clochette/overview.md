---
title: "clochette"
description: Scaleway VPS hosting Immich, published through the pangolin gateway.
sidebar:
  order: 1
  label: "Overview"
---

| Container | Domain | Role |
|---|---|---|
| `newt` | | Outbound tunnel to the [gateway](/nixos/skitarii/gateway/) |
| `immich-server` | `photos.friloux.me` | Photo gallery |
| `immich-postgres` | | PostgreSQL for Immich |
| `immich-redis` | | Redis for Immich |

## Exposure

- `photos.friloux.me` is a CNAME to `skitarii.friloux.me`. newt carries the traffic to `immich-server` on the `web` network (created by `docker-newt.nix`).
- No traefik, no crowdsec, no public web port. TLS and bans happen on skitarii.
- No pangolin SSO (the Immich app cannot pass it). Login bursts are banned by crowdsec on skitarii (`LePresidente/http-generic-401-bf`).
- SSH: Tailscale only.

## Network

| | |
|---|---|
| IPv4 | `51.159.34.135/24` static (`network.nix`), gateway `51.159.34.1`, DNS `51.159.47.28`, `51.159.47.26` |
| IPv6 | SLAAC, EUI-64 `2001:bc8:6005:1c:208:a2ff:fe0c:6ca2` (AAAA of `clochette.friloux.me`) |
| Temporary addresses | disabled (`networking.tempAddresses`): Scaleway only lets the EUI-64 address out (#108) |

:::caution
Scaleway blocks outbound 465 and 587: no direct mail. Notifications go through ntfy.sh over HTTPS.
:::

## Users

| User | Shell | Role |
|---|---|---|
| `guillaume` | fish | admin, `wheel` + `docker` |
| `weechat` | fish | persistent IRC session in zellij |

SSH keys: ed25519 and sk-ssh-ed25519 (YubiKey). Details: [Users](/nixos/clochette/users/).

## Data and backup

| Path | Content | Borg |
|---|---|---|
| `/srv/docker/photos.friloux.me/upload/` | photos, nightly DB dump in `backups/` | yes |
| `/srv/docker/photos.friloux.me/db/` | live PostgreSQL | no (the dump covers it) |
| `/home/weechat/.config/weechat` | IRC config | yes |

Daily to `ssh://backup@storage2.friloux.me/~/clochette.friloux.me`. Restore: [Immich](/nixos/operations/restore/#immich-clochette).

`traefik/`, `crowdsec.clochette.friloux.me/`, `crowdsec-manager/` under `/srv/docker/` are leftovers from the old stack: unused, not backed up.
