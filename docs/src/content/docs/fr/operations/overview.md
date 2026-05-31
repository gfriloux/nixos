---
title: Rites Opérationnels — Vue d'Ensemble
description: Procédures opérationnelles — déploiement, secrets, surveillance, dépannage, réinstallation.
---

Cette section regroupe toutes les procédures opérationnelles de la Forge.

## Opérations Courantes

| Tâche | Page |
|---|---|
| Déployer une configuration | [Commandes de Déploiement](deployment.md) |
| Éditer un secret sops | [sops-nix & Secrets](sops.md) |
| Surveiller les services | [Monitoring & Observabilité](monitoring.md) |
| Diagnostiquer un problème | [Dépannage](troubleshooting.md) |

## Opérations de Récupération

| Tâche | Page |
|---|---|
| Sauvegarder/restaurer les clés age | [Sauvegarde & Restauration des Secrets](secrets-backup.md) |
| Réinstaller exampleHost | [Réinstallation exampleHost](reinstall-examplehost.md) |
| Réinstaller clochette | [Réinstallation clochette](reinstall-clochette.md) |
| Ré-enrôler Tailscale | [Tailscale — Ré-enrôlement](tailscale.md) |

## Principe Général

Chaque modification du dépôt suit ce cycle :

1. Modifier les fichiers `.nix`
2. `just test` (linters via pre-commit)
3. `just build` ou `just build_clochette` (build sans déployer)
4. `just install` ou `just install_clochette` (déployer)
5. Valider le comportement attendu
6. Commit + push
