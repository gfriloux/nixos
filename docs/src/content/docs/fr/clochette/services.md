---
title: Services — Vue d'Ensemble
description: Patterns communs — health checks, réseaux Docker, secrets, UIDs/GIDs, dépendances.
---

Patterns standards appliqués à tous les containers Docker sur clochette pour la cohérence et la maintenabilité.

## Health Checks

Tous les containers surveillés déclarent un health check via `extraOptions` :

```nix
extraOptions = lib.kuri.docker.mkHealthCheck {
  cmd = "commande-de-test";
  startPeriod = "30s";  # délai avant premier check (défaut: 0)
};
```

`mkHealthCheck` génère les flags `--health-cmd`, `--health-interval=30s`,
`--health-timeout=10s`, `--health-retries=3`.

## Réseaux Docker

Les containers exposés via Traefik rejoignent le réseau `web`.
Les containers à usage interne (bases de données) ont leur propre réseau isolé.

```nix
networks = ["web"];          # exposé Traefik
networks = ["immich"];       # interne seulement
networks = ["immich" "web"]; # interne + Traefik
```

Les réseaux sont créés par des services systemd `docker-network-<nom>`
générés via `lib.kuri.docker.mkNetwork`.

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

Les dépendances systemd supplémentaires (ex. CrowdSec → Traefik) sont
déclarées dans `systemd.services."docker-<nom>"`.
