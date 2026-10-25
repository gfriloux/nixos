---
title: Rite of Restoration — Service Data from Borg
description: What each Borg archive holds, what it deliberately leaves out, and how to bring every database back.
---

Borg archives never contain a live database. A database copied file by file
while it is being written to is not restorable, so each one is backed up
through a consistent copy instead, and the live files are excluded.

**Restoring therefore takes two steps**: extract the files, then load each
database from its copy. Starting a database container on the extracted files
alone gives an empty database.

## What the archives hold

| Host | Service | Live data (excluded) | Consistent copy (backed up) |
|---|---|---|---|
| clochette | Immich (PostgreSQL) | `photos.friloux.me/db/` | `photos.friloux.me/upload/backups/immich-db-backup-*.sql.gz` (Immich, 02:00, last 14) |
| RogueLeader | BookStack (MariaDB) | `wow-cp.friloux.me/db/` | `wow-cp.friloux.me/dumps/*.bookstackapp.sql.gz` (wow-cp-mysqldump, 03:00 UTC, last 15) |
| RogueLeader | Uptime Kuma (SQLite) | `status.friloux.me/data/kuma.db*` | `sqlite-snapshots/uptime-kuma.db` |
| RogueLeader | Papra (SQLite) | `docs.friloux.me/data/db/db.sqlite*` | `sqlite-snapshots/papra.db` |
| RogueLeader | Mealie (SQLite) | `cuisine.home.friloux.me/data/mealie.db*` | `sqlite-snapshots/mealie.db` |

All paths are under `/srv/docker/`. Borg runs after the dumps (03:00 on
clochette, 06:00 on RogueLeader), so each archive carries that night's copies.
The SQLite snapshots are taken by the job itself, just before `borg create`.

## Common setup

The root shell is bash. As root on the host:

```bash
export BORG_PASSPHRASE=$(cat /run/secrets/services/borg/passphrase)
export BORG_RSH="ssh -i /run/secrets/services/borg/key/private"
REPO=ssh://backup@storage2.friloux.me/~/clochette.friloux.me      # or rogueleader.friloux.me
borg list --last 5 "$REPO"
```

Each host's key can only reach its own repository: RogueLeader cannot read
clochette's archives, and the other way round.

An archive whose name ends in `.failed` was written by a job that did not
finish cleanly. Prefer the most recent archive without that suffix.

Extract from `/` so paths land where the services expect them, with the
services stopped:

```bash
cd /
borg extract --progress "$REPO::ARCHIVE_NAME"
```

## Immich (clochette)

Tested on 2026-10-25: a dump restored into a scratch container held the same
9,883 assets as production, with all extensions (`vchord` 0.5.3,
`vector` 0.8.1).

1. Stop the server and the database: `systemctl stop immich-server immich-postgres`
2. Move the old datadir aside, if there is one:
   `mv /srv/docker/photos.friloux.me/db /srv/docker/photos.friloux.me/db.old`
3. Extract the archive (see above), then recreate the empty datadir:
   `systemd-tmpfiles --create`
4. Start only the database: `systemctl start immich-postgres`. It initialises
   an empty cluster with the `immich` role and an empty `immich` database.
5. Load the dump into **`immich`**:

   ```bash
   DUMP=$(ls /srv/docker/photos.friloux.me/upload/backups/immich-db-backup-*.sql.gz | tail -1)
   gunzip -c "$DUMP" \
     | sed "s/SELECT pg_catalog.set_config('search_path', '', false);/SELECT pg_catalog.set_config('search_path', 'public, pg_catalog', true);/g" \
     | docker exec -i immich-postgres psql -U immich -d immich
   ```

6. Start the server: `systemctl start immich-server`

Pitfalls:

- The dump does not create the `immich` role: the cluster must be initialised
  with `POSTGRES_USER=immich`, as production is. Restoring as `postgres`
  fails on every `OWNER TO immich`.
- The dump holds one database and has no `\connect`: it goes into whatever
  database `psql -d` names. Use `immich`, not `postgres`.
- The `sed` line comes from Immich's own restore procedure.
- Restore on the PostgreSQL image the dump was taken with (its name holds the
  Immich and PostgreSQL versions, e.g. `v3.3.5-pg17.8`).

## BookStack (RogueLeader)

Tested on 2026-10-25: a dump restored into a scratch `linuxserver/mariadb:10.5.15`
had the same 41 tables, 289 entities, 185 pages and 202 images as production.

1. Stop BookStack and the dump job:
   `systemctl stop wow-cp-bookstack wow-cp-mysqldump`
2. Rebuild the database the same way as Immich: stop `wow-cp-mariadb`, move
   `db/` aside, extract, `systemd-tmpfiles --create`, start `wow-cp-mariadb`.
3. Create the database and load the dump, dropping its first line:

   ```bash
   DUMP=/srv/docker/wow-cp.friloux.me/dumps/latest.bookstackapp.sql.gz
   docker exec wow-cp-mariadb sh -c \
     'mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "create database if not exists bookstackapp"'
   gunzip -c "$DUMP" | sed '1{/999999.*sandbox/d}' \
     | docker exec -i wow-cp-mariadb sh -c 'mysql -uroot -p"$MYSQL_ROOT_PASSWORD" bookstackapp'
   ```

4. Check that the MariaDB user BookStack logs in with (from
   `services/wow-cp/env_bookstack`) exists and has rights on `bookstackapp`.
   This step was not covered by the test.
5. Start everything again: `systemctl start wow-cp-bookstack wow-cp-mysqldump`

Pitfalls:

- The dump starts with `/*M!999999\- enable the sandbox mode */`, written by
  the recent `mariadb-dump` of the dump image. The 10.5 `mysql` client stops
  on it with `Unknown command '\-'`: the `sed` drops that line only.
- The dump does not create the database. In the test,
  `linuxserver/mariadb:10.5.15` did not create it from `MYSQL_DATABASE` either.
- BookStack keeps pages, chapters and books in a single `entities` table:
  there is no `pages` table.

## SQLite services (RogueLeader)

Each snapshot passed `PRAGMA quick_check` on 2026-10-25. A snapshot is a
complete database: restoring it means putting the file back.

| Service | Unit | Snapshot | Live path | Owner |
|---|---|---|---|---|
| Uptime Kuma | `uptime-kuma` | `uptime-kuma.db` | `status.friloux.me/data/kuma.db` | `root:root` |
| Papra | `papra` | `papra.db` | `docs.friloux.me/data/db/db.sqlite` | `papra:papra` |
| Mealie | `mealie` | `mealie.db` | `cuisine.home.friloux.me/data/mealie.db` | `911:911` |

For each one, after extracting the archive:

```bash
systemctl stop uptime-kuma
cd /srv/docker
rm -f status.friloux.me/data/kuma.db-wal status.friloux.me/data/kuma.db-shm
cp sqlite-snapshots/uptime-kuma.db status.friloux.me/data/kuma.db
chown root:root status.friloux.me/data/kuma.db
systemctl start uptime-kuma
```

Remove the `-wal` and `-shm` files before copying: a stale WAL next to a
restored database would be replayed into it.
