---
title: "BookStack"
description: "Wiki at wow-cp.friloux.me: BookStack, MariaDB, nightly SQL dump."
---

<https://wow-cp.friloux.me>, through the gateway, no SSO. BookStack throttles sign-in itself (5 tries per minute per account and IP); `APP_PROXIES=*` makes it see the visitor's IP. Nix: `docker-wow-cp.nix`.

| Container | Image | Role |
|---|---|---|
| `wow-cp-bookstack` | `linuxserver/bookstack` | app, networks `wow-cp` + `web` |
| `wow-cp-mariadb` | `linuxserver/mariadb:10.5.15` | database, network `wow-cp` |
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
docker exec wow-cp-mariadb mysqladmin ping -h localhost --silent

# Manual dump
docker exec wow-cp-mariadb mysqldump -u root --all-databases \
  > /srv/docker/wow-cp.friloux.me/dumps/manual_$(date +%Y%m%d).sql
```

Restore: [BookStack](/nixos/operations/restore/#bookstack-rogueleader) (drop the dump's first line for the 10.5 client, create the database first).

:::caution
The mysqldump image requires TLS by default, MariaDB 10.5 does not offer it: dumps failed silently while the container stayed healthy. `MYSQL_SSL_OPTS = "--skip-ssl"` (private `wow-cp` network only). Check that `dumps/` gets new files.
:::
