---
title: Monitoring & Observabilité
description: Surveillance des services — health checks, timers, logs, Borg backup.
---

Vue d'ensemble des mécanismes de surveillance en place sur l'infrastructure.

## Notifications de Pannes (ntfy.sh)

Tous les containers sur clochette avec le label `friloux.me/health-watch = "true"`
sont surveillés automatiquement par le module `notify-docker`.

Deux mécanismes :

| Mécanisme | Déclencheur | Action |
|---|---|---|
| `notify-failure@` | Service systemd passe en `failed` | Notification ntfy.sh |
| `docker-health-watch@` (timer 30s) | `docker inspect` retourne `unhealthy` | `docker kill` → systemd restart → ntfy.sh |

Les notifications arrivent sur le topic ntfy.sh configuré dans `services/ntfy/topic`.

## Vérifier l'État des Containers

```bash
# Vue rapide — tous les containers
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.RunningFor}}"

# Santé détaillée d'un container
docker inspect --format='{{.Name}} : {{.State.Health.Status}}' traefik

# Santé de tous les containers surveillés
for c in traefik crowdsec wow-cp-bookstack wow-cp-mariadb immich-server immich-postgres; do
  echo "$c : $(docker inspect --format='{{.State.Health.Status}}' $c 2>/dev/null || echo 'not found')"
done
```

## Health Check Endpoints

| Service | Commande de Test |
|---|---|
| traefik | `curl -s http://127.0.0.1:8080/ping` |
| crowdsec | `curl -s http://localhost:8080/health` |
| bookstack | `curl -s http://localhost/status` |
| mariadb | `docker exec wow-cp-mariadb mysqladmin ping -h localhost --silent` |
| immich | `curl -s http://localhost:2283/api/server/ping` |
| postgres | `docker exec immich-postgres pg_isready -U immich -d immich` |
| redis | `docker exec immich-redis redis-cli ping` |

## Timers systemd Actifs

```bash
# Lister tous les timers et leur prochain déclenchement
systemctl list-timers --all

# Timers spécifiques à surveiller
systemctl list-timers | grep -E "borg|health-watch|logrotate"
```

## Borg Backup

```bash
# Statut du dernier backup
systemctl status borgbackup-job-remote

# Journal du dernier backup
journalctl -u borgbackup-job-remote --since today

# Liste des archives disponibles
BORG_PASSPHRASE=$(cat /run/secrets/services/borg/passphrase) \
BORG_RSH="ssh -i /run/secrets/services/borg/key/private" \
borg list ssh://backup@storage2.friloux.me/~/clochette.friloux.me

# Vérification d'intégrité manuelle
systemctl start borgbackup-check
```

## Logs

```bash
# Logs d'un service Docker via journald
journalctl -u docker-traefik -f
journalctl -u docker-wow-cp-bookstack --since "1 hour ago"

# Logs applicatifs Traefik (fichier rotaté)
tail -f /srv/docker/traefik/logs/traefik.log

# Logrotate — vérifier la dernière exécution
journalctl -u logrotate --since today
```

## Uptime Kuma (à Venir)

Uptime Kuma sera installé sur une prochaine machine NixOS pour fournir
une surveillance externe indépendante de clochette.

Voir [RogueLeader — Planification](../rogueleader/planning.md).
