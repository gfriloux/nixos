---
title: Design & Prérequis
description: Architecture de RogueLeader — partitionnement, accès réseau, évolutions prévues.
---

Décisions d'architecture et prérequis pour la maintenance et l'évolution du serveur dédié.

## Partitionnement (disko)

Disque unique `/dev/sda`, GPT :

| Partition | Taille | Rôle |
|---|---|---|
| 1 Mo | BIOS boot | GRUB |
| 4 Go | swap | — |
| reste | `/` ext4 | Système + données |

## Accès

Réseau local : `192.168.0.10` (alias `rogueleader.home` dans ssh.nix de exampleHost).
Déploiement depuis exampleHost via SSH local.

## Évolutions Prévues

- Documenter les procédures de réinstallation spécifiques à RogueLeader
- Valider la procédure de rotation de clé age post-réinstall
- Envisager l'ajout de Tailscale pour accès distant sans dépendre du réseau local
