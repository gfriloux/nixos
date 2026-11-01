---
title: "Exploitation"
description: Les procédures, au quotidien et en cas de panne.
sidebar:
  order: 1
  label: "Vue d’ensemble"
---

## Changer la config

```bash
just test                 # linters (pre-commit)
just build_<machine>      # build sans déployer (just build pour exampleHost)
just install_<machine>    # déployer (just install pour exampleHost)
```

Garder un shell root ouvert avant de toucher à sudo ou aux utilisateurs. Détail : [Déploiement](/nixos/fr/operations/deployment/).

## Au quotidien

| Tâche | Page |
|---|---|
| Éditer un secret | [Secrets](/nixos/fr/architecture/secrets/) |
| Surveiller | [Monitoring](/nixos/fr/operations/monitoring/), [Notifications de panne](/nixos/fr/operations/notifications/) |
| Diagnostiquer | [Dépannage](/nixos/fr/operations/troubleshooting/) |

## En cas de panne

| Tâche | Page |
|---|---|
| Restaurer des données | [Restaurer depuis Borg](/nixos/fr/operations/restore/) |
| Récupérer les clés age | [Sauvegarde des clés age](/nixos/fr/operations/secrets-backup/) |
| Réinstaller | [exampleHost](/nixos/fr/operations/reinstall-examplehost/), [clochette](/nixos/fr/operations/reinstall-clochette/), [skitarii](/nixos/fr/operations/reinstall-skitarii/), [RogueLeader](/nixos/fr/operations/reinstall-rogueleader/) |
| Ré-enrôler Tailscale | [Ré-enrôlement Tailscale](/nixos/fr/operations/tailscale/) |
