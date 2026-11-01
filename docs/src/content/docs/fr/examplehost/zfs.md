---
title: "ZFS"
description: Maintenance du miroir ZFS, Docker sur ZFS, zrepl depuis storage2.
---

Organisation et datasets : [Stockage](/nixos/fr/architecture/storage/).

## Commandes

```bash
zpool status                       # santé des pools
zfs list -r rpool bpool            # occupation
zfs list -t snapshot -r rpool      # snapshots
zpool scrub rpool && zpool scrub bpool
zpool status -w                    # attendre la fin du scrub

docker info | grep "Storage Driver"   # doit dire zfs (les couches sont des datasets sous /var/lib/docker)

sudo zrepl status
zfs list -t snapshot rpool/backup/storage2
```

## zrepl

Job pull `storage2` dans `services.nix`, toutes les 10 min, depuis `storage2.retrohive.fr` (ssh+stdinserver, root) vers `rpool/backup/storage2`, chiffrement hérité.

| Côté | Garde les snapshots `zrepl_*` |
|---|---|
| exampleHost (récepteur) | tous pendant 7 jours, puis 1 par 30 jours sur 3 périodes |
| storage2 (émetteur) | les 10 derniers |

## Réglages de boot

```nix
boot.zfs.forceImportRoot = false;                 # posé par la relic zfs : pas d'import forcé
fileSystems."/home".neededForBoot = true;         # sur tous les datasets, /home compris, par uniformité
boot.loader.efi.canTouchEfiVariables = false;     # GRUB en mode amovible
boot.zfs.devNodes = "/dev/disk/by-id/";           # IDs des disques dans boot.nix et disko.nix : mettre à jour les deux si un disque change
```
