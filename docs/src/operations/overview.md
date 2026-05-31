# Déploiement & maintenance

Cette section regroupe toutes les procédures opérationnelles.

## Opérations courantes

| Tâche | Page |
|---|---|
| Déployer une configuration | [Commandes de déploiement](deployment.md) |
| Éditer un secret sops | [sops-nix & secrets](sops.md) |
| Surveiller les services | [Monitoring & observabilité](monitoring.md) |
| Diagnostiquer un problème | [Dépannage](troubleshooting.md) |

## Opérations de récupération

| Tâche | Page |
|---|---|
| Sauvegarder/restaurer les clés age | [Sauvegarde & restauration des secrets](secrets-backup.md) |
| Réinstaller exampleHost | [Réinstallation exampleHost](reinstall-examplehost.md) |
| Réinstaller clochette | [Réinstallation clochette](reinstall-clochette.md) |
| Ré-enrôler Tailscale | [Tailscale — ré-enrôlement](tailscale.md) |

## Principe général

Chaque modification du dépôt suit ce cycle :

1. Modifier les fichiers `.nix`
2. `just test` (linters via pre-commit)
3. `just build` ou `just build_clochette` (build sans déployer)
4. `just install` ou `just install_clochette` (déployer)
5. Valider le comportement attendu
6. Commit + push
