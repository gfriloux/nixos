---
title: "BookStack"
description: "Wiki sur wow-cp.friloux.me : BookStack, MariaDB, dump SQL nocturne."
---

<https://wow-cp.friloux.me>, par la passerelle, sans SSO. BookStack limite lui-même les connexions (5 essais par minute par compte et IP) ; `APP_PROXIES=*` lui fait voir l'IP du visiteur. Nix : `docker-wow-cp.nix`.

| Conteneur | Image | Rôle |
|---|---|---|
| `wow-cp-bookstack` | `linuxserver/bookstack` | appli, réseaux `wow-cp` + `web` |
| `wow-cp-mariadb` | `linuxserver/mariadb:10.5.15` | base, réseau `wow-cp` |
| `wow-cp-mysqldump` | `fradelg/mysql-cron-backup` | dumps dans `dumps/` (healthcheck propre) |

| Chemin sous `/srv/docker/wow-cp.friloux.me/` | Contenu | Borg |
|---|---|---|
| `data/` | uploads, config linuxserver | oui |
| `db/` | MariaDB en cours d'usage | non |
| `dumps/` | dumps SQL | oui |

Secrets (sops) : `services/wow-cp/env_bookstack`, `env_mariadb`, `env_mysqldump`.

## Commandes

```bash
# Santé
docker exec wow-cp-bookstack curl -fs http://localhost/status | grep '"database":true'
docker exec wow-cp-mariadb mysqladmin ping -h localhost --silent

# Dump manuel
docker exec wow-cp-mariadb mysqldump -u root --all-databases \
  > /srv/docker/wow-cp.friloux.me/dumps/manual_$(date +%Y%m%d).sql
```

Restauration : [BookStack](/nixos/fr/operations/restore/#bookstack-rogueleader) (retirer la première ligne du dump pour le client 10.5, créer la base d'abord).

:::caution
L'image mysqldump exige TLS par défaut, MariaDB 10.5 ne le propose pas : les dumps échouaient en silence alors que le conteneur restait healthy. `MYSQL_SSL_OPTS = "--skip-ssl"` (réseau privé `wow-cp` uniquement). Vérifier que `dumps/` reçoit de nouveaux fichiers.
:::
