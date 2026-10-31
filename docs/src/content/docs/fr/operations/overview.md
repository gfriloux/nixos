---
title: "Exploitation"
description: Procédures opérationnelles — déploiement, secrets, surveillance, dépannage, réinstallation.
sidebar:
  order: 1
  label: "Vue d’ensemble"
---

Cette section regroupe toutes les procédures opérationnelles de la Forge.

## Opérations Courantes

| Tâche | Page |
|---|---|
| Déployer une configuration | [Commandes de Déploiement](/nixos/fr/operations/deployment/) |
| Éditer un secret sops | [sops-nix & Secrets](/nixos/fr/operations/sops/) |
| Surveiller les services | [Monitoring & Observabilité](/nixos/fr/operations/monitoring/) |
| Diagnostiquer un problème | [Dépannage](/nixos/fr/operations/troubleshooting/) |

## Opérations de Récupération

| Tâche | Page |
|---|---|
| Sauvegarder/restaurer les clés age | [Sauvegarde & Restauration des Secrets](/nixos/fr/operations/secrets-backup/) |
| Restaurer les données des services depuis Borg | [Restauration des Données depuis Borg](/nixos/fr/operations/restore/) |
| Réinstaller exampleHost | [Réinstallation exampleHost](/nixos/fr/operations/reinstall-examplehost/) |
| Réinstaller clochette | [Réinstallation clochette](/nixos/fr/operations/reinstall-clochette/) |
| Réinstaller skitarii | [Réinstallation skitarii](/nixos/fr/operations/reinstall-skitarii/) |
| Ré-enrôler Tailscale | [Tailscale — Ré-enrôlement](/nixos/fr/operations/tailscale/) |

## Principe Général

Chaque modification du dépôt suit ce cycle :

1. Modifier les fichiers `.nix`
2. `just test` (linters via pre-commit)
3. `just build` ou `just build_clochette` (build sans déployer)
4. `just install` ou `just install_clochette` (déployer)
5. Valider le comportement attendu
6. Commit + push
