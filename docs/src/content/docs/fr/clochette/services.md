---
title: Services — Vue d'Ensemble
description: Patterns communs — health checks, réseaux Docker, secrets, UIDs/GIDs, dépendances.
---

Patterns standards appliqués à tous les containers Docker sur clochette pour la cohérence et la maintenabilité.

## Health Checks

Tous les containers surveillés déclarent un health check via `extraOptions` :

```nix
extraOptions = inputs.stc.lib.docker.mkHealthCheck {
  cmd = "commande-de-test";
  startPeriod = "30s";  # délai de grâce avant que les échecs comptent (défaut: 30s)
};
```

`mkHealthCheck` (fourni par l'input de flake STC) génère les flags `--health-cmd`,
`--health-interval=30s`, `--health-timeout=10s`, `--health-start-period`,
`--health-retries=3`. L'associer au label `stc.docker/health-watch` pour obtenir
redémarrages et notifications (voir [Notifications de Pannes](notifications.md)).

## Réseaux Docker

Les containers publiés par la passerelle pangolin rejoignent le réseau `web`,
où `newt` les joint par leur nom (voir [La Porte](../skitarii/gateway.md)).
Les containers à usage interne (bases de données) ont leur propre réseau isolé.

```nix
networks = ["web"];          # joignable par newt
networks = ["immich"];       # interne seulement
networks = ["immich" "web"]; # interne + newt
```

Les réseaux sont créés par des services systemd `docker-network-<nom>`
générés via `inputs.stc.lib.docker.mkNetwork pkgs "<nom>"`.

## Secrets

Les variables d'environnement sensibles passent par des `environmentFiles` sops :

```nix
environmentFiles = [
  config.sops.secrets."services/<nom>/env".path
];
```

Le fichier `env` contient des paires `CLE=valeur` en clair (déchiffrées par sops-nix).

## UIDs/GIDs

Les containers rootless ont un utilisateur système dédié déclaré dans le même fichier :

```nix
users.users.immich-postgres = { uid = 999; isSystemUser = true; group = "immich-postgres"; ... };
users.groups.immich-postgres = { gid = 999; };
```

Les répertoires de données sont créés avec le bon propriétaire via `systemd.tmpfiles.rules`.

## Ordre de Démarrage

Les dépendances inter-containers sont déclarées avec `dependsOn` :

```nix
"immich-server" = {
  dependsOn = ["immich-postgres" "immich-redis"];
  ...
};
```

Les dépendances systemd supplémentaires (ex. le réseau `web` avant newt et
immich-server, dans `docker-newt.nix`) sont
déclarées dans `systemd.services."docker-<nom>"`.
