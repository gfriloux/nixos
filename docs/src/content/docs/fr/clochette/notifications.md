---
title: Notifications de Pannes
description: Module notify-docker — surveillance automatique, timers, flux ntfy.sh.
---

L'Astropathe qui veille sur tous les démons liés — surveillance automatique et notifications d'omens funestes via ntfy.sh.

## Ce qui est Généré Automatiquement

Pour chaque container surveillé, le module crée :

- Un bloc `systemd.services` avec `OnFailure`, `Restart = "on-failure"`, `RestartSec = 30s`, `StartLimitBurst = 3`
- Un timer `docker-health-watch@<nom>` qui tourne toutes les 30 secondes
- Le service template `docker-health-watch@<nom>` qui tue le container si `unhealthy`
- Le service template `notify-failure@<nom>` qui envoie une notification ntfy.sh

**Ne pas déclarer ces éléments manuellement dans les fichiers `docker-*.nix`.**

## Ajouter la Surveillance à un Container

Ajouter le label dans la définition du container (en dernier) :

```nix
labels = {
  # ... autres labels traefik ...
  "friloux.me/health-watch" = "true";
};
```

Et s'assurer que le container a un health check défini avec `extraOptions` :

```nix
extraOptions = lib.kuri.docker.mkHealthCheck {
  cmd = "curl -fs http://localhost/health";
  startPeriod = "30s";  # optionnel
};
```

## Flux de Notification

```text
Container → unhealthy
    └── docker-health-watch@ → docker kill <container>
            └── systemd détecte la mort → restart
                    └── si StartLimitBurst atteint → failed
                            └── notify-failure@ → ntfy.sh push
```

## Vérifier les Timers de Surveillance

```bash
systemctl list-timers | grep health-watch

# Déclencher manuellement (test)
systemctl start docker-health-watch@traefik
```

## ntfy.sh

Le topic est stocké dans `sops.secrets."services/ntfy/topic"`.
Les notifications incluent le hostname de la machine et le nom du service.
