---
title: rogueleader — Serveur Dédié
description: Configuration du serveur dédié domestique — services Docker internes, Papra public via Traefik, backup.
---

Serveur dédié domestique hébergeant les services internes : monitoring de disponibilité, gestion de recettes, interface backup.

## Configuration Actuelle

| Paramètre | Valeur |
|---|---|
| Rôle | Serveur domestique interne |
| Accès réseau local | `rogueleader.home` (192.168.0.10) |
| OS | NixOS 25.11 |
| Disque | `/dev/sda`, ext4, GPT (via disko) |
| sops | Clé age dérivée du SSH host key |
| stateVersion | `25.11` |

## Services Docker Actifs

| Container | Rôle |
|---|---|
| `traefik` | Reverse proxy + TLS (Let's Encrypt) |
| `crowdsec` | WAF / protection DDoS |
| `borg-ui` | Interface web Borg backup |
| `mealie` | Gestionnaire de recettes |
| `uptime-kuma` | Monitoring de disponibilité externe |
| `papra` | Gestion documentaire (docs.friloux.me) |

## Exposition Publique

Papra (`docs.friloux.me`) est servi vers la noosphère via Traefik + CrowdSec,
exactement comme sur clochette. RogueLeader étant sur le réseau local, la box
redirige les ports 80/443 vers `192.168.0.10` ; les certificats Let's Encrypt
sont émis via le challenge TLS-ALPN-01 sur le port 443. Les autres services
restent internes.

## Backup

Configuré avec borgbackup vers `storage2.friloux.me` (même pattern que clochette).
Les données Papra (`/srv/docker/docs.friloux.me`) sont incluses dans le backup.

## Notes Importantes

- sops dérive la clé age depuis `/etc/ssh/ssh_host_ed25519_key` (comme clochette)
- Après réinstallation : mettre à jour `.sops.yaml` avec la nouvelle clé age publique
  (voir [Sauvegarde & Restauration des Secrets](../operations/secrets-backup.md))
- Déploiement depuis exampleHost : `just install_rogueleader`
- Home Manager : `just home_rogueleader`
