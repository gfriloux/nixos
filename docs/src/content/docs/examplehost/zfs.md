---
title: Pools & Mirrors — ZFS on exampleHost
description: Commands for inspecting and maintaining ZFS mirrors, snapshots, and the zrepl backup system.
---

ZFS on exampleHost guards data in twin Samsung mirrors. The following rites inspect and maintain the pools.

See also [Vaults of the Machine-Spirit](../architecture/storage.md) for the architectural overview.

## Commands for Maintenance

```bash
# Pool status
zpool status

# Disk usage
zfs list -r rpool bpool

# Existing snapshots
zfs list -t snapshot -r rpool

# Begin manual scrub
zpool scrub rpool
zpool scrub bpool
# Track progress
zpool status -w
```

## ZFS & Bound Daemons (Docker)

Docker uses ZFS as the storage driver on exampleHost.
Image layers and volumes are datasets beneath `/var/lib/docker`.

```bash
# Verify the storage driver
docker info | grep "Storage Driver"
zfs list | grep docker
```

## zrepl — The Snapshot Archive

zrepl pulls snapshots from `storage2.retrohive.fr` (the archive-shrine)
into `rpool/backup/storage2` on exampleHost.

```bash
# Job status
sudo zrepl status

# List received snapshots
zfs list -t snapshot rpool/backup/storage2
```

Retention is configured: 7 days (all) + 3 months (30 days per month).

## Important Notes

- `zfs.forceImportRoot = false` — NixOS does not force-import pools at boot
- `neededForBoot = true` on all ZFS datasets (including `/home`) for uniformity
- `canTouchEfiVariables = false` — GRUB is installed in removable mode, no EFI variables are touched
- Disk IDs are hardcoded in `boot.nix` — if disks change, update both `boot.nix` and `disko.nix`
