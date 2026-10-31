---
title: rogueleader — Serveur Dédié
description: Configuration du serveur dédié domestique — services Docker internes, Papra et BookStack publics via la passerelle pangolin, backup.
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
| `newt` | Tunnel sortant vers la passerelle pangolin de skitarii |
| `borg-ui` | Interface web Borg backup |
| `mealie` | Gestionnaire de recettes |
| `uptime-kuma` | Monitoring de disponibilité externe |
| `papra` | Gestion documentaire (docs.friloux.me) |
| `wow-cp-bookstack` | Wiki BookStack (wow-cp.friloux.me) |
| `wow-cp-mariadb` | MariaDB pour BookStack |
| `wow-cp-mysqldump` | Dump SQL cron |

## Exposition Publique

Chaque service web (mealie, borg-ui, uptime-kuma, papra, BookStack) est publié
par la passerelle pangolin de skitarii : chaque nom est un CNAME vers
`skitarii.friloux.me`, et `newt` achemine le trafic par un tunnel sortant
jusqu'aux conteneurs du réseau `web`. TLS, crowdsec et les certificats vivent sur
skitarii (voir [La Porte](../skitarii/gateway.md)). RogueLeader ne fait tourner
ni traefik ni crowdsec, n'ouvre aucun port web et n'a besoin d'aucune
redirection de port sur la box.

## Backup

Configuré avec borgbackup vers `storage2.friloux.me` (même pattern que clochette).
Les données Papra (`/srv/docker/docs.friloux.me`) sont incluses dans le backup.

## Notes Importantes

- sops dérive la clé age depuis `/etc/ssh/ssh_host_ed25519_key` (comme clochette)
- Après réinstallation : mettre à jour `.sops.yaml` avec la nouvelle clé age publique
  (voir [Sauvegarde & Restauration des Secrets](../operations/secrets-backup.md))
- Déploiement depuis exampleHost : `just install_rogueleader`
- Home Manager : `just home_rogueleader`
