---
title: "Monitoring"
description: Ce qui surveille quoi, et les commandes pour vérifier à la main.
---

| Quoi | Par | Alerte |
|---|---|---|
| Conteneurs (healthcheck) | `stc-docker-health-watch@`, toutes les 30 s : `unhealthy` → `docker kill` → restart systemd | ntfy, voir [Notifications de panne](/nixos/fr/operations/notifications/) |
| Unités en échec | `stc-notify-failure@` (`OnFailure`) | ntfy |
| Borg | job quotidien (`postHook`) + `borgbackup-check` hebdo (`--verify-data`), sur clochette, skitarii, RogueLeader | ntfy à chaque run, succès ou échec |
| Un job planifié qui cesse de réussir | relic STC `heartbeat` : ping sur succès uniquement → moniteur Push Uptime Kuma | ntfy, une fois la fenêtre écoulée sans ping |
| Services web vus de dehors | Uptime Kuma sur RogueLeader, page `status.friloux.me` | ntfy |
| Nœuds et ressources pangolin | règles d'alerte pangolin | ntfy, voir [Passerelle](/nixos/fr/skitarii/gateway/) |

Uptime Kuma tourne à la maison : si skitarii tombe, la page publique tombe, les alertes continuent.

## Silence (#87)

Un job qui cesse de tourner n'échoue pas et ne notifie rien. Chaque unité
surveillée pingue un moniteur Push Kuma quand elle réussit ; Kuma alerte quand
les pings s'arrêtent.

| Hôte | Unité | Fenêtre | Secret |
|---|---|---|---|
| clochette, skitarii, RogueLeader | `borgbackup-job-remote` | 36 h | `services/kuma/borg` |
| clochette, skitarii, RogueLeader | `borgbackup-check` | 8 jours | `services/kuma/borg-check` |
| RogueLeader | `wow-cp-dump-age` (05:30, un dump de moins de 26 h) | 36 h | `services/kuma/wow-cp-dumps` |

```bash
journalctl -u stc-heartbeat-borgbackup-job-remote -n 5   # "no ping" = le run n'a pas réussi
```

Nouveau moniteur : type Push dans Kuma, 0 retry, son URL dans le fichier sops
de l'hôte, puis `stc.relics.heartbeat.units.<unité>.urlFile` à côté du job.

Pas couvert :

- RogueLeader en panne : Kuma tombe avec, personne n'alerte.
- skitarii en panne : les pings passent par la passerelle pour joindre Kuma,
  donc tous les moniteurs Push alertent après leur fenêtre.
- exampleHost : éteint la plupart du temps, le silence y est normal.

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
