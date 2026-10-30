---
title: The Gate — Pangolin, Gerbil, Traefik & CrowdSec
description: How the pangolin gateway on skitarii is wired, what lives where, and the traps already met.
---

The gate-shrine runs the pangolin stack, backed up nightly to storage2,
with healthchecks and ntfy notifications on every container.

## Layout

```text
Internet (IPv4 + IPv6)
    │
    └── gerbil  ── publishes 80/443 TCP, 443/51820/21820 UDP
          │        (WireGuard for newt tunnels)
          └── traefik  (lives in gerbil's network namespace)
                ├── entrypoints web + websecure → crowdsec@file (bouncer)
                ├── file provider  → pangolin.friloux.me (dashboard + API)
                └── HTTP provider  → http://pangolin:3001/api/v1/traefik-config
                                     (every resource created in pangolin)

docker network "pangolin" (IPv4 + fd49:e7d1:9e38::/64)
    pangolin · gerbil (+ traefik) · crowdsec · crowdsec-manager
```

| Container | Image | Role |
|---|---|---|
| `pangolin` | `fosrl/pangolin:ee-*` | Dashboard and API, SQLite in `/srv/docker/pangolin.friloux.me/config`. Enterprise Edition, free personal-use license entered at `/admin/license` |
| `gerbil` | `fosrl/gerbil` | WireGuard endpoint, owns the published ports |
| `traefik` | `traefik` | Reverse proxy, Let's Encrypt (HTTP-01), plugins badger + crowdsec bouncer |
| `crowdsec` | `crowdsecurity/crowdsec` | STC relic, reads traefik's access log |
| `crowdsec-manager` | `hhftechnology/crowdsec-manager` | CrowdSec UI, raw Docker socket |

All of it lives in `systems/x86_64-linux/skitarii/docker-pangolin.nix` and
`docker-crowdsec-manager.nix`; the crowdsec relic is set in `default.nix`.

## Where the Configuration Comes From

| Source | Content | Written by |
|---|---|---|
| traefik HTTP provider | Every resource, route, auth rule created in the dashboard | pangolin, live, from its database |
| traefik `dynamic_config.yml` | Dashboard routes and the `badger`, `crowdsec`, `redirect-to-https` middlewares | Nix (read-only, from the store) |
| traefik `traefik_config.yml` | Entrypoints, plugins, ACME, access log | Nix (read-only, from the store) |
| pangolin `config.yml` | Dashboard URL, base domain `friloux.me`, flags | sops template (carries `server.secret`) |

Everything configured in pangolin works. Only crowdsec-manager's feature
that edits traefik's files does not: those changes go through Nix.

## Secrets

In `secrets/skitarii.yaml`:

- `services/pangolin/secret` — pangolin's `server.secret`
- `services/crowdsec/bouncer-key` — crowdsec registers it at start
  (`BOUNCER_KEY_traefik`), traefik reads it from a mounted file

## Publishing a Service

1. CNAME `<name>` → `skitarii.friloux.me.` at Gandi, **before** anything
   queries the name (a cached `NXDOMAIN` lasts 3 hours).
2. In pangolin: a resource on the right site. **Local** for a container on
   skitarii's `pangolin` network; a newt tunnel for another machine.
3. Keep SSO on unless the service is meant to be public.

## crowdsec-manager

Published as the pangolin resource `crowdsec.friloux.me` (local site,
target `http://crowdsec-manager:8080`), behind pangolin SSO **and TOTP**.
It holds the raw Docker socket: reaching it means root on skitarii.

:::caution[Ward]
pangolin security keys are a way to log in, not a second factor. Only an
enabled TOTP makes pangolin ask for a code after the password. Check in a
private window, where no dashboard session exists.
:::

## Checks

```bash
# Bouncer registered, access log read
sudo docker exec crowdsec cscli bouncers list
sudo docker exec crowdsec cscli metrics show acquisition

# Which address traefik sees (must be the visitor's, IPv4 or IPv6)
sudo tail -n 3 /srv/docker/pangolin.friloux.me/traefik-logs/access.log \
  | nix run nixpkgs#jq -- -r '[.ClientHost, .RouterName, .DownstreamStatus] | @tsv'

# End-to-end ban test (5 min), then wait 70 s before testing
sudo docker exec crowdsec cscli decisions add --ip <IP> --duration 5m --reason test
```

## Backup, Health and Alerts

| What | Where | Detail |
|---|---|---|
| Borg backup | `backup.nix` | 04:00 to `storage2.friloux.me/~/skitarii.friloux.me`, `borg check` weekly. Restore: [Rite of Restoration](../operations/restore.md) |
| SQLite snapshots | `/srv/docker/sqlite-snapshots` | pangolin, crowdsec, crowdsec-manager (settings, history), taken by the job before `borg create` |
| Log rotation | `docker-pangolin.nix` | `access.log` daily, 14 kept, rename then `USR1` |
| Healthchecks | `docker-pangolin.nix` | pangolin `:3001/api/v1/`, gerbil `:3004/healthz`, `traefik healthcheck`; crowdsec and crowdsec-manager ship their own |
| Notifications | `default.nix` | `stc.relics.docker.notify`, ntfy topic in `secrets/skitarii.yaml` |

## Traps Already Met

- **badger v1.8.0** fails traefik's plugin integrity check, and traefik then
  disables *every* plugin: all dashboard routes fail with `invalid middleware
  "badger@file"`. Pinned to v1.7.0 (traefik/traefik#14115).
- **Ban test shows 200**: the bouncer in `live` mode caches a clean IP for 60
  seconds. Wait before concluding.
- **IPv6 visitors seen as a private address**: without IPv6 on the Docker
  network, published ports go through `docker-proxy` and traefik sees the
  Docker gateway, which crowdsec whitelists. The network now has a ULA /64;
  changing its options requires stopping the containers and `docker network
  rm pangolin`, the creation script never recreates an existing network.
- **No ntfy notification, no error**: ntfy.sh rate-limits IPv6 per /64, and
  skitarii's /64 is shared between OVH VPS, so its anonymous quota is spent
  by the neighbours (`429`). Every ntfy call here uses `curl -4`, and
  `--fail` so a `429` fails the unit instead of exiting 0.
- **Startup errors** (`connection refused` on `pangolin:3001`, `no such host
  crowdsec`, `crowdsec@file does not exist` on internal routers) stop within
  seconds of a restart. If they persist, they are real.

## Not Done Yet

- AppSec (request inspection) in crowdsec
