---
title: "ZFS"
description: ZFS mirror maintenance, Docker on ZFS, zrepl pull from storage2.
---

Layout and datasets: [Storage](/nixos/architecture/storage/).

## Commands

```bash
zpool status                       # pool health
zfs list -r rpool bpool            # usage
zfs list -t snapshot -r rpool      # snapshots
zpool scrub rpool && zpool scrub bpool
zpool status -w                    # wait for the scrub

docker info | grep "Storage Driver"   # must say zfs (layers are datasets under /var/lib/docker)

sudo zrepl status
zfs list -t snapshot rpool/backup/storage2
```

## zrepl

Pull job `storage2` in `services.nix`, every 10 min, from `storage2.retrohive.fr` (ssh+stdinserver, root) into `rpool/backup/storage2`, encryption inherited.

| Side | Keeps `zrepl_*` snapshots |
|---|---|
| exampleHost (receiver) | all for 7 days, then 1 per 30 days for 3 periods |
| storage2 (sender) | last 10 |

## Boot settings

| Setting | Why |
|---|---|
| `boot.zfs.forceImportRoot = false` | no forced pool import at boot |
| `neededForBoot = true` on every dataset, `/home` included | uniformity |
| `canTouchEfiVariables = false` | GRUB in removable mode |
| Disk IDs in `boot.nix` and `disko.nix` | replacing a disk means updating both |
