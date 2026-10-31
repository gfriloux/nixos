---
title: Notifications de Pannes
description: Relic docker-notify de STC — surveillance automatique, timers, flux ntfy.sh.
---

L'Astropathe qui veille sur tous les démons liés — surveillance automatique et notifications d'omens funestes via ntfy.sh.

L'Astropathe est la relic `relics-docker-notify` de STC (`stc.relics.docker.notify`),
importée depuis l'input de flake `stc`. Elle fonctionne de la même façon sur
chaque machine qui fait tourner des containers (clochette, RogueLeader,
skitarii) ; les exemples de cette page sont pris sur clochette.

## Activer la Relic

Chaque machine l'active dans son `default.nix` et fournit `notifyCommand`, le
bout de shell qui envoie l'alerte. STC fournit le câblage, pas le transport :
la commande reçoit `STC_NOTIFY_SERVICE` (l'unité en défaut) et
`STC_NOTIFY_HOSTNAME` dans son environnement, et lit elle-même ses secrets.

```nix
stc.relics.docker.notify = {
  enable = true;
  notifyCommand = ''
    ${pkgs.curl}/bin/curl -s \
      -H "Title: [$STC_NOTIFY_HOSTNAME] $STC_NOTIFY_SERVICE en défaut" \
      -d "$STC_NOTIFY_SERVICE est passé en état failed" \
      "https://ntfy.sh/$(cat ${config.sops.secrets."services/ntfy/topic".path})"
  '';
};
```

Sur skitarii l'appel est `curl -4 -sS --fail` : ntfy.sh limite l'IPv6 par /64,
et OVH partage ce /64 entre clients.

## Ce qui est Généré Automatiquement

Pour chaque container portant le label `stc.docker/health-watch = "true"`, la relic crée :

- Sur l'unité du container : `OnFailure = stc-notify-failure@%p.service`, `Restart = "on-failure"`, `RestartSec = 30s`, `StartLimitBurst = 3` sur `StartLimitIntervalSec = 300s`
- Un timer `stc-docker-health-watch@<nom>` qui tourne toutes les 30 secondes (premier passage 240 s après le boot)
- Le service template `stc-docker-health-watch@<nom>` qui fait `docker kill` sur le container si `docker inspect` le dit `unhealthy`
- Le service template `stc-notify-failure@<unité>` qui exécute `notifyCommand`

**Ne pas déclarer ces éléments manuellement dans les fichiers `docker-*.nix`.**
Les surcharges propres à un container (`after`/`requires` supplémentaires)
peuvent toujours y aller ; NixOS les fusionne.

`stc-notify-failure@` sert aussi d'`OnFailure` pour des unités hors Docker : le
check borg du `backup.nix` de chaque machine l'utilise.

## Ajouter la Surveillance à un Container

Ajouter le label dans la définition du container (en dernier, après les autres labels) :

```nix
labels = {
  # ... autres labels ...
  "stc.docker/health-watch" = "true";
};
```

Et s'assurer que le container a un health check défini avec `extraOptions` :

```nix
extraOptions = inputs.stc.lib.docker.mkHealthCheck {
  cmd = "curl -fs http://localhost/health";
  startPeriod = "30s";  # optionnel, 30s par défaut
};
```

La relic refuse de construire si un container surveillé n'a aucun health check
visible. Si l'image déclare déjà un `HEALTHCHECK` (invisible à l'évaluation),
le dire avec un second label au lieu de `mkHealthCheck` :

```nix
labels = {
  "stc.docker/health-cmd-in-image" = "true";
  "stc.docker/health-watch" = "true";
};
```

## Flux de Notification

```text
Container → unhealthy
    └── stc-docker-health-watch@ → docker kill <container>
            └── systemd détecte la mort → restart
                    └── si StartLimitBurst atteint → failed
                            └── stc-notify-failure@ → notifyCommand → ntfy.sh push
```

Une fois la limite atteinte, systemd ne redémarre plus le container : il reste
arrêté, et la notification est le seul signal.

## Vérifier les Timers de Surveillance

```bash
systemctl list-timers | grep health-watch

# Déclencher manuellement (test)
systemctl start stc-docker-health-watch@immich-server
```

## ntfy.sh

Le topic est stocké dans `sops.secrets."services/ntfy/topic"`, déclaré dans le
`default.nix` de chaque machine. Le titre porte le hostname et l'unité en défaut.
