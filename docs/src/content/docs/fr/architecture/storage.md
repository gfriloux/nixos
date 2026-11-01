---
title: "Stockage"
description: Disques et sauvegardes des quatre machines, datasets ZFS d'exampleHost.
---

| Machine | Disque | Swap | Sauvegarde |
|---|---|---|---|
| exampleHost | ZFS miroir, 2× NVMe 980 PRO 1 To (disko) | 4 Go par disque, chiffré | zrepl tire `storage2.retrohive.fr`, voir [ZFS](/nixos/fr/examplehost/zfs/) |
| clochette | `/dev/sda` MBR : `/boot` ext2, `/` ext4 | chiffré | Borg 03:00 |
| skitarii | `/dev/sda` GPT/BIOS (disko) : `/` ext4 | 2 Go | Borg 04:00 |
| RogueLeader | `/dev/sda` GPT/BIOS (disko) : `/` ext4 | 4 Go | Borg 06:00 |

Données des conteneurs : `/srv/docker/<domaine>/`. Borg envoie vers
`ssh://backup@storage2.friloux.me/~/<machine>.friloux.me` ; storage2 fait lui-même le prune.
Restaurer : [Restauration](/nixos/fr/operations/restore/).

## Datasets d'exampleHost

| Pool | Dataset | Montage |
|---|---|---|
| bpool (grub2) | `nixos/root` | `/boot` |
| rpool | `nixos/root` | `/` |
| rpool | `nixos/home` | `/home` |
| rpool | `nixos/var/lib` | `/var/lib` |
| rpool | `nixos/var/log` | `/var/log` |
| rpool | `backup/storage2` | aucun (reçu par zrepl) |

Les deux pools en `ashift=12`, `autotrim=on`. Datasets en `mountpoint=legacy`,
montés par `boot.nix`. `/data2` : HDD ext4 en `nofail`, le boot continue sans lui.
