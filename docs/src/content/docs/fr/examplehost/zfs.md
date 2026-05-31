---
title: Configuration ZFS
description: Pools ZFS, datasets, snapshots, zrepl, maintenance — exampleHost.
---

Voir aussi [Reliquaires & Systèmes de Fichiers](../architecture/storage.md) pour la vue d'ensemble.

## Commandes de Maintenance

```bash
# État des pools
zpool status

# Utilisation
zfs list -r rpool bpool

# Snapshots existants
zfs list -t snapshot -r rpool

# Lancer un scrub manuellement
zpool scrub rpool
zpool scrub bpool
# Suivre la progression
zpool status -w
```

## ZFS et Docker

Docker utilise ZFS comme storage driver sur exampleHost.
Les layers des images et les volumes sont des datasets sous `/var/lib/docker`.

```bash
# Vérifier
docker info | grep "Storage Driver"
zfs list | grep docker
```

## zrepl — Backup ZFS

zrepl tire des snapshots depuis `storage2.retrohive.fr` (serveur de backup)
vers `rpool/backup/storage2` sur exampleHost.

```bash
# Statut du job
sudo zrepl status

# Voir les snapshots reçus
zfs list -t snapshot rpool/backup/storage2
```

Rétention configurée : 7 jours (tous) + 3 mois (30j par mois).

## Notes Importantes

- `zfs.forceImportRoot = false` : NixOS n'importe jamais les pools de force au démarrage
- `neededForBoot = true` sur tous les datasets ZFS (y compris `/home`) pour uniformité
- `canTouchEfiVariables = false` : GRUB installé en mode removable, pas de variables EFI
- Les IDs disques sont hardcodés dans `boot.nix` — si les disques changent, mettre à jour `boot.nix` et `disko.nix`
