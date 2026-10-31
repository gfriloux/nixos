---
title: "RogueLeader"
description: Serveur maison. BookStack, Mealie, Papra, Uptime Kuma, Borg UI, publiés par la passerelle pangolin.
sidebar:
  order: 1
  label: "Vue d’ensemble"
---

| Conteneur | Domaine | Rôle |
|---|---|---|
| `newt` | | Tunnel sortant vers la [passerelle](/nixos/fr/skitarii/gateway/) |
| `wow-cp-bookstack` | `wow-cp.friloux.me` | Wiki ([BookStack](/nixos/fr/rogueleader/bookstack/)) |
| `wow-cp-mariadb` | | MariaDB pour BookStack |
| `wow-cp-mysqldump` | | Dump SQL nocturne |
| `papra` | `docs.friloux.me` | Documents ([Papra](/nixos/fr/rogueleader/papra/)) |
| `mealie` | `cuisine.friloux.me` | Recettes |
| `uptime-kuma` | `status.friloux.me` | Page de statut |
| `borg-ui` | `borg-ui.friloux.me` | UI web Borg |

Chaque domaine est un CNAME vers `skitarii.friloux.me`. Ni traefik, ni crowdsec, aucun port ouvert, aucune redirection sur la box.

## Hôte

| | |
|---|---|
| Réseau | `rogueleader.home` (`192.168.0.10`), LAN uniquement |
| Disque | `/dev/sda`, GPT via disko : 1M BIOS boot, 4G swap, `/` ext4. GRUB, BIOS |
| sops | clé age dérivée de `/etc/ssh/ssh_host_ed25519_key`. Après une réinstallation : nouvelle clé dans `.sops.yaml`, voir [Sauvegarde des clés age](/nixos/fr/operations/secrets-backup/) |
| stateVersion | `25.11` |

## Déployer

```bash
just install_rogueleader   # système
just home_rogueleader      # Home Manager seul
```

## Sauvegarde

Borg vers `ssh://backup@storage2.friloux.me/~/rogueleader.friloux.me`, `backup.nix`.

| Chemin | Note |
|---|---|
| `/srv/docker/wow-cp.friloux.me` | `db/` en cours d'usage exclu, le dump SQL le couvre |
| `/srv/docker/docs.friloux.me` | SQLite en cours d'usage exclu |
| `/srv/docker/status.friloux.me` | SQLite en cours d'usage exclu |
| `/srv/docker/cuisine.home.friloux.me` | SQLite en cours d'usage exclu |
| `/srv/docker/sqlite-snapshots` | copies des trois bases SQLite, faites avant `borg create` |
