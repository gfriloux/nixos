# Summary

[Introduction](introduction.md)

# Architecture

- [Vue d'ensemble](architecture/overview.md)
  - [Machines & systèmes](architecture/machines.md)
  - [Stockage & systèmes de fichiers](architecture/storage.md)
  - [Réseau & DNS](architecture/networking.md)
  - [Gestion des secrets](architecture/secrets.md)

# exampleHost

- [exampleHost — poste de travail](examplehost/overview.md)
  - [Configuration ZFS](examplehost/zfs.md)
  - [AMD GPU](examplehost/amd-gpu.md)
  - [Plasma 6](examplehost/plasma6.md)
  - [Home Manager](examplehost/home-manager.md)

# clochette

- [clochette — serveur](clochette/overview.md)
  - [Traefik](clochette/traefik.md)
  - [CrowdSec](clochette/crowdsec.md)
  - [Services](clochette/services.md)
    - [Papra](clochette/papra.md)
    - [BookStack](clochette/bookstack.md)
  - [Notifications de pannes](clochette/notifications.md)
  - [Utilisateurs & homes](clochette/users.md)

# rogueleader

- [rogueleader — planification](rogueleader/overview.md)
  - [Design & prérequis](rogueleader/planning.md)

# Opérations

- [Déploiement & maintenance](operations/overview.md)
  - [Commandes de déploiement](operations/deployment.md)
  - [sops-nix & secrets](operations/sops.md)
  - [Sauvegarde & restauration des secrets](operations/secrets-backup.md)
  - [Réinstallation — exampleHost](operations/reinstall-examplehost.md)
  - [Réinstallation — clochette](operations/reinstall-clochette.md)
  - [Réinstallation — RogueLeader](operations/reinstall-rogueleader.md)
  - [Tailscale — ré-enrôlement](operations/tailscale.md)
  - [Monitoring & observabilité](operations/monitoring.md)
  - [Dépannage](operations/troubleshooting.md)
