---
title: "Monitoring"
description: Ce qui surveille quoi, et les commandes pour vérifier à la main.
---

| Quoi | Par | Alerte |
|---|---|---|
| Conteneurs (healthcheck) | `stc-docker-health-watch@`, toutes les 30 s : `unhealthy` → `docker kill` → restart systemd | ntfy, voir [Notifications de panne](/nixos/fr/operations/notifications/) |
| Unités en échec | `stc-notify-failure@` (`OnFailure`) | ntfy |
| Borg | job quotidien (`postHook`) + `borgbackup-check` hebdo (`--verify-data`), sur clochette, skitarii, RogueLeader | ntfy à chaque run, succès ou échec |
| Services web vus de dehors | Uptime Kuma sur RogueLeader, page `status.friloux.me` | ntfy |
| Nœuds et ressources pangolin | règles d'alerte pangolin | ntfy, voir [Passerelle](/nixos/fr/skitarii/gateway/) |

Uptime Kuma tourne à la maison : si skitarii tombe, la page publique tombe, les alertes continuent.

## Conteneurs

```bash
docker ps --format "table {{.Names}}\t{{.Status}}"
docker inspect --format '{{json .State.Health}}' immich-server   # statut + sortie des derniers checks
journalctl -u immich-server --since "1 hour ago"
systemctl list-timers | grep health-watch
```

Les healthchecks tournent dans le conteneur : un `curl localhost:<port>` depuis l'hôte
échoue, aucun port n'est publié. Tester avec `docker exec <conteneur> <cmd>`.

## Borg

```bash
systemctl status borgbackup-job-remote
journalctl -u borgbackup-job-remote --since today
sudo systemctl start borgbackup-check      # vérification d'intégrité à la main
```

Lister les archives : [Restaurer depuis Borg](/nixos/fr/operations/restore/).

## Logs web

Tout passe par le traefik de skitarii :

```bash
sudo tail -f /srv/docker/pangolin.friloux.me/traefik-logs/access.log
```
