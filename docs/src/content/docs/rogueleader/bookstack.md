---
title: "BookStack"
description: "Wiki at wow-cp.friloux.me: BookStack, MariaDB, nightly SQL dump."
---

<https://wow-cp.friloux.me>, through the gateway, no SSO. BookStack throttles sign-in itself (5 tries per minute per account and IP); `APP_PROXIES=*` makes it see the visitor's IP. Nix: `docker-wow-cp.nix`.

| Container | Image | Role |
|---|---|---|
| `wow-cp-bookstack` | `linuxserver/bookstack` | app, networks `wow-cp` + `web` |
| `wow-cp-mariadb` | `linuxserver/mariadb` | database, network `wow-cp` |
| `wow-cp-mysqldump` | `fradelg/mysql-cron-backup` | dumps into `dumps/` (own healthcheck) |

| Path under `/srv/docker/wow-cp.friloux.me/` | Content | Borg |
|---|---|---|
| `data/` | uploads, linuxserver config | yes |
| `db/` | live MariaDB | no |
| `dumps/` | SQL dumps | yes |

Secrets (sops): `services/wow-cp/env_bookstack`, `env_mariadb`, `env_mysqldump`.

## Commands

```bash
# Health
docker exec wow-cp-bookstack curl -fs http://localhost/status | grep '"database":true'
docker exec wow-cp-mariadb mariadb-admin ping -h localhost --silent

# Manual dump
docker exec wow-cp-mariadb mariadb-dump -u root --all-databases \
  > /srv/docker/wow-cp.friloux.me/dumps/manual_$(date +%Y%m%d).sql
```

Restore: [BookStack](/nixos/operations/restore/#bookstack-rogueleader) (create the database first).

:::caution
A failing dump leaves the container healthy: it went unseen for weeks in 2026. `wow-cp-dump-age` alerts when `dumps/` has no file younger than 26 h.
:::
