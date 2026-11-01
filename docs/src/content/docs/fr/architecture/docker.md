---
title: "Motifs Docker"
description: "Motifs Docker : healthchecks, réseaux, secrets, UID, ordre de démarrage."
---

| Besoin | Motif |
|---|---|
| Healthcheck | `extraOptions = inputs.stc.lib.docker.mkHealthCheck { cmd = "..."; startPeriod = "30s"; };` (intervalle 30s, timeout 10s, 3 essais). Ajouter le label `stc.docker/health-watch` pour relance + alerte : [Notifications de panne](/nixos/fr/operations/notifications/) |
| Publié par la passerelle | `networks = ["web"];` newt joint le conteneur par son nom |
| Interne uniquement (bases) | son propre réseau, ex. `networks = ["immich"];` |
| Les deux | `networks = ["immich" "web"];` |
| Créer un réseau | `inputs.stc.lib.docker.mkNetwork pkgs "<nom>"` (unité systemd `docker-network-<nom>`) |
| Secrets en variables d'env | `environmentFiles = [ config.sops.secrets."services/<nom>/env".path ];` (`CLÉ=valeur` en clair) |
| Conteneur rootless | `users.users.<nom>` / `users.groups.<nom>` avec uid/gid fixes dans le même fichier, dossiers de données via `systemd.tmpfiles.rules` |
| Démarrer après un autre conteneur | `dependsOn = ["immich-postgres" "immich-redis"];` |
| Autre ordre systemd | `systemd.services.<unité>`, du nom du conteneur, `docker-newt` pour newt (ex. réseau `web` avant newt dans `docker-newt.nix`) |
