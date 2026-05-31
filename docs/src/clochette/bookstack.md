# BookStack

Wiki personnel. URL : <https://wow-cp.friloux.me>

## Stack

| Container | Rôle |
|---|---|
| `wow-cp-bookstack` | Application BookStack (linuxserver) |
| `wow-cp-mariadb` | Base de données MariaDB |
| `wow-cp-mysqldump` | Dump SQL cron automatique |

Réseau interne dédié `wow-cp` + réseau `web` pour l'exposition Traefik.

## Données

```
/srv/docker/wow-cp.friloux.me/
├── data/    # Fichiers BookStack (uploads, config linuxserver)
├── db/      # Données MariaDB
└── dumps/   # Dumps SQL (mysqldump cron)
```

## Health checks

```bash
# BookStack — vérifie que la DB répond
docker exec wow-cp-bookstack curl -fs http://localhost/status | grep '"database":true'

# MariaDB
docker exec wow-cp-mariadb mysqladmin ping -h localhost --silent
```

## Backup de la base de données

Le container `wow-cp-mysqldump` effectue des dumps automatiques dans `/srv/docker/wow-cp.friloux.me/dumps/`.
Ces dumps sont inclus dans le backup Borg.

Dump manuel :

```bash
docker exec wow-cp-mariadb mysqldump \
  -u root \
  --all-databases > /srv/docker/wow-cp.friloux.me/dumps/manual_$(date +%Y%m%d).sql
```

## Restauration de la base de données

```bash
# Arrêter BookStack
systemctl stop docker-wow-cp-bookstack

# Restaurer depuis un dump
docker exec -i wow-cp-mariadb mysql -u root < /srv/docker/wow-cp.friloux.me/dumps/dump.sql

# Redémarrer
systemctl start docker-wow-cp-bookstack
```

## Secrets

Trois fichiers env séparés :
- `services/wow-cp/env_bookstack` : config BookStack (APP_KEY, DB_HOST, DB_PASSWORD…)
- `services/wow-cp/env_mariadb` : MYSQL_ROOT_PASSWORD, MYSQL_DATABASE…
- `services/wow-cp/env_mysqldump` : credentials mysqldump
