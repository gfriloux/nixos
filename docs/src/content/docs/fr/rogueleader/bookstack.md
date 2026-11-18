---
title: "BookStack"
description: "Wiki sur wow-cp.friloux.me : BookStack, MariaDB, dump SQL nocturne."
---

<https://wow-cp.friloux.me>, par la passerelle, sans SSO. BookStack limite lui-même les connexions (5 essais par minute par compte et IP) ; `APP_PROXIES=*` lui fait voir l'IP du visiteur. Nix : `docker-wow-cp.nix`.

| Conteneur | Image | Rôle |
|---|---|---|
| `wow-cp-bookstack` | `linuxserver/bookstack` | appli, réseaux `wow-cp` + `web` |
| `wow-cp-mariadb` | `linuxserver/mariadb` | base, réseau `wow-cp` |
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
docker exec wow-cp-mariadb mariadb-admin ping -h localhost --silent

# Dump manuel
docker exec wow-cp-mariadb mariadb-dump -u root --all-databases \
  > /srv/docker/wow-cp.friloux.me/dumps/manual_$(date +%Y%m%d).sql
```

Restauration : [BookStack](/nixos/fr/operations/restore/#bookstack-rogueleader) (créer la base d'abord).

:::caution
Un dump en échec laisse le conteneur healthy : c'est passé inaperçu pendant des semaines en 2026. `wow-cp-dump-age` alerte quand `dumps/` n'a aucun fichier de moins de 26 h.
:::
