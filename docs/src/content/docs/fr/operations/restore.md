---
title: Restauration des Données depuis Borg
description: Ce que contient chaque archive Borg, ce qu'elle exclut volontairement, et comment remettre chaque base en service.
---

Les archives Borg ne contiennent jamais une base de données vivante. Une base
copiée fichier par fichier pendant qu'elle écrit n'est pas restaurable : chaque
base est donc sauvegardée via une copie cohérente, et ses fichiers vivants sont
exclus.

**Restaurer se fait donc en deux temps** : extraire les fichiers, puis charger
chaque base depuis sa copie. Démarrer un conteneur de base sur les seuls
fichiers extraits donne une base vide.

## Contenu des archives

| Hôte | Service | Données vivantes (exclues) | Copie cohérente (sauvegardée) |
|---|---|---|---|
| clochette | Immich (PostgreSQL) | `photos.friloux.me/db/` | `photos.friloux.me/upload/backups/immich-db-backup-*.sql.gz` (Immich, 02:00, 14 dernières) |
| RogueLeader | BookStack (MariaDB) | `wow-cp.friloux.me/db/` | `wow-cp.friloux.me/dumps/*.bookstackapp.sql.gz` (wow-cp-mysqldump, 03:00 UTC, 15 dernières) |
| RogueLeader | Uptime Kuma (SQLite) | `status.friloux.me/data/kuma.db*` | `sqlite-snapshots/uptime-kuma.db` |
| RogueLeader | Papra (SQLite) | `docs.friloux.me/data/db/db.sqlite*` | `sqlite-snapshots/papra.db` |
| RogueLeader | Mealie (SQLite) | `cuisine.home.friloux.me/data/mealie.db*` | `sqlite-snapshots/mealie.db` |
| skitarii | pangolin (SQLite) | `pangolin.friloux.me/config/db/db.sqlite*` | `sqlite-snapshots/pangolin.db` |
| skitarii | crowdsec (SQLite) | `crowdsec.skitarii.friloux.me/data/crowdsec.db*` | `sqlite-snapshots/crowdsec.db` |
| skitarii | crowdsec-manager (SQLite) | `crowdsec-manager/data/settings.db*`, `history.db*` | `sqlite-snapshots/crowdsec-manager-settings.db`, `crowdsec-manager-history.db` |

Tous les chemins sont sous `/srv/docker/`. Borg passe après les dumps (03:00
sur clochette, 06:00 sur RogueLeader) : chaque archive contient les copies de
la nuit. skitarii n'a pas de dump à attendre et passe à 04:00. Les copies SQLite sont faites par le job lui-même, juste avant
`borg create`.

## Préparation commune

Le shell de root est bash. En root sur l'hôte :

```bash
export BORG_PASSPHRASE=$(cat /run/secrets/services/borg/passphrase)
export BORG_RSH="ssh -i /run/secrets/services/borg/key/private"
REPO=ssh://backup@storage2.friloux.me/~/clochette.friloux.me      # ou rogueleader / skitarii.friloux.me
borg list --last 5 "$REPO"
```

La clé de chaque hôte n'ouvre que son propre dépôt : RogueLeader ne peut pas
lire les archives de clochette, et inversement. Idem pour skitarii.

Une archive dont le nom finit par `.failed` vient d'un job qui ne s'est pas
terminé proprement. Préférer la plus récente sans ce suffixe.

Extraire depuis `/` pour que les chemins tombent là où les services les
attendent, services arrêtés :

```bash
cd /
borg extract --progress "$REPO::NOM_ARCHIVE"
```

## Immich (clochette)

Testé le 2026-10-25 : un dump restauré dans un conteneur jetable contenait les
mêmes 9 883 assets que la production, avec toutes les extensions (`vchord`
0.5.3, `vector` 0.8.1).

1. Arrêter le serveur et la base : `systemctl stop immich-server immich-postgres`
2. Mettre l'ancien datadir de côté, s'il existe :
   `mv /srv/docker/photos.friloux.me/db /srv/docker/photos.friloux.me/db.old`
3. Extraire l'archive (voir plus haut), puis recréer le datadir vide :
   `systemd-tmpfiles --create`
4. Démarrer la base seule : `systemctl start immich-postgres`. Elle initialise
   un cluster vide avec le rôle `immich` et une base `immich` vide.
5. Charger le dump dans **`immich`** :

   ```bash
   DUMP=$(ls /srv/docker/photos.friloux.me/upload/backups/immich-db-backup-*.sql.gz | tail -1)
   gunzip -c "$DUMP" \
     | sed "s/SELECT pg_catalog.set_config('search_path', '', false);/SELECT pg_catalog.set_config('search_path', 'public, pg_catalog', true);/g" \
     | docker exec -i immich-postgres psql -U immich -d immich
   ```

6. Démarrer le serveur : `systemctl start immich-server`

Pièges :

- Le dump ne crée pas le rôle `immich` : le cluster doit être initialisé avec
  `POSTGRES_USER=immich`, comme en production. Restaurer en `postgres` échoue
  sur chaque `OWNER TO immich`.
- Le dump contient une seule base et aucun `\connect` : il va dans la base que
  nomme `psql -d`. Utiliser `immich`, pas `postgres`.
- La ligne `sed` vient de la procédure de restauration d'Immich.
- Restaurer sur l'image PostgreSQL avec laquelle le dump a été fait (son nom
  porte les versions d'Immich et de PostgreSQL, par ex. `v3.3.5-pg17.8`).

## BookStack (RogueLeader)

Testé le 2026-10-25 : un dump restauré dans un `linuxserver/mariadb:10.5.15`
jetable avait les mêmes 41 tables, 289 entités, 185 pages et 202 images que la
production.

1. Arrêter BookStack et le job de dump :
   `systemctl stop wow-cp-bookstack wow-cp-mysqldump`
2. Reconstruire la base comme pour Immich : arrêter `wow-cp-mariadb`, mettre
   `db/` de côté, extraire, `systemd-tmpfiles --create`, démarrer
   `wow-cp-mariadb`.
3. Créer la base et charger le dump, sans sa première ligne :

   ```bash
   DUMP=/srv/docker/wow-cp.friloux.me/dumps/latest.bookstackapp.sql.gz
   docker exec wow-cp-mariadb sh -c \
     'mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "create database if not exists bookstackapp"'
   gunzip -c "$DUMP" | sed '1{/999999.*sandbox/d}' \
     | docker exec -i wow-cp-mariadb sh -c 'mysql -uroot -p"$MYSQL_ROOT_PASSWORD" bookstackapp'
   ```

4. Vérifier que l'utilisateur MariaDB de BookStack (dans
   `services/wow-cp/env_bookstack`) existe et a les droits sur `bookstackapp`.
   Le test n'a pas couvert cette étape.
5. Tout redémarrer : `systemctl start wow-cp-bookstack wow-cp-mysqldump`

Pièges :

- Le dump commence par `/*M!999999\- enable the sandbox mode */`, écrit par
  le `mariadb-dump` récent de l'image de dump. Le client `mysql` 10.5 s'arrête
  dessus avec `Unknown command '\-'` : le `sed` ne retire que cette ligne.
- Le dump ne crée pas la base. Pendant le test, `linuxserver/mariadb:10.5.15`
  ne l'a pas créée non plus depuis `MYSQL_DATABASE`.
- BookStack range pages, chapitres et livres dans une seule table `entities` :
  il n'y a pas de table `pages`.

## Services SQLite (RogueLeader)

Chaque copie a passé `PRAGMA quick_check` le 2026-10-25. Une copie est une
base complète : la restaurer, c'est remettre le fichier en place.

| Service | Unité | Copie | Chemin vivant | Propriétaire |
|---|---|---|---|---|
| Uptime Kuma | `uptime-kuma` | `uptime-kuma.db` | `status.friloux.me/data/kuma.db` | `root:root` |
| Papra | `papra` | `papra.db` | `docs.friloux.me/data/db/db.sqlite` | `papra:papra` |
| Mealie | `mealie` | `mealie.db` | `cuisine.home.friloux.me/data/mealie.db` | `911:911` |

Pour chacun, après l'extraction de l'archive :

```bash
systemctl stop uptime-kuma
cd /srv/docker
rm -f status.friloux.me/data/kuma.db-wal status.friloux.me/data/kuma.db-shm
cp sqlite-snapshots/uptime-kuma.db status.friloux.me/data/kuma.db
chown root:root status.friloux.me/data/kuma.db
systemctl start uptime-kuma
```

Supprimer les fichiers `-wal` et `-shm` avant la copie : un WAL périmé à côté
d'une base restaurée serait rejoué dedans.

## Services SQLite (skitarii)

La copie de pangolin a passé `PRAGMA integrity_check` le 2026-10-30. Même
procédure que sur RogueLeader : arrêter l'unité, supprimer `-wal`/`-shm`,
remettre la copie. Tout appartient à `root:root`.

| Service | Unité | Copie | Chemin vivant |
|---|---|---|---|
| pangolin | `docker-pangolin` | `pangolin.db` | `pangolin.friloux.me/config/db/db.sqlite` |
| crowdsec | `crowdsec` | `crowdsec.db` | `crowdsec.skitarii.friloux.me/data/crowdsec.db` |
| crowdsec-manager | `crowdsec-manager` | `crowdsec-manager-settings.db` | `crowdsec-manager/data/settings.db` |
| crowdsec-manager | `crowdsec-manager` | `crowdsec-manager-history.db` | `crowdsec-manager/data/history.db` |

```bash
systemctl stop docker-pangolin docker-gerbil docker-traefik
cd /srv/docker
rm -f pangolin.friloux.me/config/db/db.sqlite-wal pangolin.friloux.me/config/db/db.sqlite-shm
cp sqlite-snapshots/pangolin.db pangolin.friloux.me/config/db/db.sqlite
systemctl start docker-pangolin docker-gerbil docker-traefik
```

gerbil et traefik s'arrêtent avec pangolin : tous deux tirent leur
configuration de lui.
