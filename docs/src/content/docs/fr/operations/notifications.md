---
title: "Notifications de panne"
description: La relic docker-notify de STC, timers de surveillance, alertes ntfy.sh.
---

Relic STC `stc.relics.docker.notify`, identique sur clochette, RogueLeader et skitarii.

## Déroulé

1. Le conteneur passe `unhealthy`.
2. Le timer `stc-docker-health-watch@<nom>` (toutes les 30 s, premier passage 240 s après le boot) le voit et fait `docker kill`.
3. systemd le relance (`Restart = "on-failure"`, `RestartSec = 30s`).
4. 3 échecs en 300 s (`StartLimitBurst`) : l'unité passe `failed` et **reste arrêtée**.
5. `OnFailure = stc-notify-failure@%p.service` lance `notifyCommand` : push ntfy.sh.

## Surveiller un conteneur

```nix
extraOptions = inputs.stc.lib.docker.mkHealthCheck {
  cmd = "curl -fs http://localhost/health";
  startPeriod = "30s";  # optionnel, 30s par défaut
};
labels = {
  # ... autres labels ...
  "stc.docker/health-watch" = "true";  # en dernier
};
```

Le build échoue si un conteneur surveillé n'a pas de healthcheck. Si l'image a son propre `HEALTHCHECK`, ajouter `"stc.docker/health-cmd-in-image" = "true";` à la place de `mkHealthCheck`.

:::caution
Ne pas déclarer `OnFailure`, `Restart`, `StartLimitBurst` ni les timers dans `docker-*.nix` : la relic les génère. Des `after`/`requires` en plus, c'est possible (NixOS fusionne).
:::

`stc-notify-failure@` sert aussi d'`OnFailure` pour des unités hors Docker (le borg check de `backup.nix`).

## notifyCommand

Dans le `default.nix` de chaque hôte. Il reçoit `STC_NOTIFY_SERVICE` et `STC_NOTIFY_HOSTNAME` ; le topic ntfy est le secret sops `services/ntfy/topic`.

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

skitarii utilise `curl -4 -sS --fail` : ntfy.sh limite l'IPv6 par /64, partagé entre clients OVH.

## Vérifier

```bash
systemctl list-timers | grep health-watch
systemctl start stc-docker-health-watch@immich-server   # lancement manuel
```
