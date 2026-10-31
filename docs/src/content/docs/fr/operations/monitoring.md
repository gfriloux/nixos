---
title: Monitoring & Observabilité
description: Surveillance des services — health checks, timers, logs, Borg backup.
---

Vue d'ensemble des mécanismes de surveillance en place sur l'infrastructure.

## Notifications de Pannes (ntfy.sh)

Sur chaque machine qui fait tourner des containers (clochette, RogueLeader,
skitarii), les containers portant le label `stc.docker/health-watch = "true"`
sont surveillés automatiquement par la relic `relics-docker-notify` de STC.
Voir [Notifications de Pannes](../clochette/notifications.md).

Deux mécanismes :

| Mécanisme | Déclencheur | Action |
|---|---|---|
| `stc-notify-failure@` | Service systemd passe en `failed` | `notifyCommand` → notification ntfy.sh |
| `stc-docker-health-watch@` (timer 30s) | `docker inspect` retourne `unhealthy` | `docker kill` → systemd restart → ntfy.sh |

Les notifications arrivent sur le topic ntfy.sh configuré dans `services/ntfy/topic`. Les exemples ci-dessous sont pris sur clochette.

## Vérifier l'État des Containers

```bash
# Vue rapide — tous les containers
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.RunningFor}}"

# Santé détaillée d'un container
docker inspect --format='{{.Name}} : {{.State.Health.Status}}' immich-server

# Santé de tous les containers surveillés
for c in newt immich-server immich-postgres immich-redis; do
  echo "$c : $(docker inspect --format='{{.State.Health.Status}}' $c 2>/dev/null || echo 'not found')"
done
```

## Health Check Endpoints

| Service | Commande de Test |
|---|---|
| newt | `docker exec newt test -f /tmp/healthy` |
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
journalctl -u docker-newt -f
journalctl -u docker-immich-server --since "1 hour ago"

# Les logs d'accès web sont sur skitarii, dont le traefik tient la passerelle
sudo tail -f /srv/docker/pangolin.friloux.me/traefik-logs/access.log

# Logrotate — vérifier la dernière exécution
journalctl -u logrotate --since today
```

## Uptime Kuma

Uptime Kuma tourne sur RogueLeader (container `uptime-kuma`) et sert la page de
statut `status.friloux.me`, publiée par la passerelle pangolin. Si skitarii
tombe, la page publique tombe avec lui, mais Uptime Kuma continue de tourner à
la maison et d'alerter par ntfy.

Voir [RogueLeader](../rogueleader/overview.md).
