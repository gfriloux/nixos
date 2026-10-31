---
title: BookStack
description: Wiki personnel — stack Docker, données, health checks, backup/restauration.
---

Wiki personnel, chronique du savoir et des lores. Tourne sur RogueLeader, exposé publiquement à <https://wow-cp.friloux.me> via la passerelle pangolin de skitarii (tunnel newt, sans SSO). BookStack limite lui-même la connexion (5 essais par minute par compte et IP) ; `APP_PROXIES=*` dans son env lui fait lire l'IP du visiteur.

## Stack

| Container | Rôle |
|---|---|
| `wow-cp-bookstack` | Application BookStack (linuxserver) |
| `wow-cp-mariadb` | Base de données MariaDB |
| `wow-cp-mysqldump` | Dump SQL cron automatique |

Réseau interne dédié `wow-cp` + réseau `web`, par lequel newt le joint.

## Données

```text
/srv/docker/wow-cp.friloux.me/
├── data/    # Fichiers BookStack (uploads, config linuxserver)
├── db/      # Données MariaDB
└── dumps/   # Dumps SQL (mysqldump cron)
```

## Health Checks

```bash
# BookStack — vérifie que la DB répond
docker exec wow-cp-bookstack curl -fs http://localhost/status | grep '"database":true'

# MariaDB
docker exec wow-cp-mariadb mysqladmin ping -h localhost --silent
```

## Backup de la Base de Données

Le container `wow-cp-mysqldump` effectue des dumps automatiques dans `/srv/docker/wow-cp.friloux.me/dumps/`.
Ces dumps sont inclus dans le backup Borg.

Dump manuel :

```bash
docker exec wow-cp-mariadb mysqldump \
  -u root \
  --all-databases > /srv/docker/wow-cp.friloux.me/dumps/manual_$(date +%Y%m%d).sql
```

## Restauration de la Base de Données

Voir [Restauration des Données depuis Borg](../operations/restore.md#bookstack-rogueleader) :
le dump doit perdre sa première ligne pour qu'un client 10.5 l'accepte, et la
base doit être créée avant.

## Secrets

Trois fichiers env séparés :

- `services/wow-cp/env_bookstack` : config BookStack (APP_KEY, DB_HOST, DB_PASSWORD…)
- `services/wow-cp/env_mariadb` : MYSQL_ROOT_PASSWORD, MYSQL_DATABASE…
- `services/wow-cp/env_mysqldump` : credentials mysqldump
