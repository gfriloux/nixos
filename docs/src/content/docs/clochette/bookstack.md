---
title: BookStack — The Personal Wiki
description: Wiki service at wow-cp.friloux.me with MariaDB backend and automated backups.
---

BookStack is the personal wiki, a chronicle of lore and knowledge. Accessible at https://wow-cp.friloux.me.

## Stack

| Daemon | Role |
|---|---|
| `wow-cp-bookstack` | BookStack application (linuxserver image) |
| `wow-cp-mariadb` | MariaDB database |
| `wow-cp-mysqldump` | Automated SQL backup cron |

Dedicated internal network `wow-cp` + `web` network for Traefik exposure.

## Data Vault

```
/srv/docker/wow-cp.friloux.me/
├── data/    # BookStack files (uploads, linuxserver config)
├── db/      # MariaDB data
└── dumps/   # SQL dumps (mysqldump cron)
```

## Health Checks

```bash
# BookStack — verifies DB is reachable
docker exec wow-cp-bookstack curl -fs http://localhost/status | grep '"database":true'

# MariaDB
docker exec wow-cp-mariadb mysqladmin ping -h localhost --silent
```

## Database Backup

The `wow-cp-mysqldump` daemon automatically dumps the database into `/srv/docker/wow-cp.friloux.me/dumps/`.
These dumps are included in Borg backup.

Manual dump:

```bash
docker exec wow-cp-mariadb mysqldump \
  -u root \
  --all-databases > /srv/docker/wow-cp.friloux.me/dumps/manual_$(date +%Y%m%d).sql
```

## Database Restoration

```bash
# Stop BookStack
systemctl stop docker-wow-cp-bookstack

# Restore from a dump
docker exec -i wow-cp-mariadb mysql -u root < /srv/docker/wow-cp.friloux.me/dumps/dump.sql

# Restart
systemctl start docker-wow-cp-bookstack
```

## Secrets

Three separate env files:
- `services/wow-cp/env_bookstack`: BookStack config (APP_KEY, DB_HOST, DB_PASSWORD, etc.)
- `services/wow-cp/env_mariadb`: MYSQL_ROOT_PASSWORD, MYSQL_DATABASE, etc.
- `services/wow-cp/env_mysqldump`: mysqldump credentials
