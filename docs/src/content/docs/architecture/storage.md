---
title: "Storage"
description: Disks and backups of the four machines, exampleHost's ZFS datasets.
---

| Machine | Disk | Swap | Backup |
|---|---|---|---|
| exampleHost | ZFS mirror, 2× NVMe 980 PRO 1 TB (disko) | 4 GB per disk, encrypted | zrepl pulls `storage2.retrohive.fr`, see [ZFS](/nixos/examplehost/zfs/) |
| clochette | `/dev/sda` MBR: `/boot` ext2, `/` ext4 | encrypted | Borg 03:00 |
| skitarii | `/dev/sda` GPT/BIOS (disko): `/` ext4 | 2 GB | Borg 04:00 |
| RogueLeader | `/dev/sda` GPT/BIOS (disko): `/` ext4 | 4 GB | Borg 06:00 |

Container data: `/srv/docker/<domain>/`. Borg sends to
`ssh://backup@storage2.friloux.me/~/<machine>.friloux.me`; storage2 prunes on its own.
Restore: [Restore](/nixos/operations/restore/).

## exampleHost datasets

| Pool | Dataset | Mount |
|---|---|---|
| bpool (grub2) | `nixos/root` | `/boot` |
| rpool | `nixos/root` | `/` |
| rpool | `nixos/home` | `/home` |
| rpool | `nixos/var/lib` | `/var/lib` |
| rpool | `nixos/var/log` | `/var/log` |
| rpool | `backup/storage2` | none (received by zrepl) |

Both pools use `ashift=12`, `autotrim=on`. Datasets are `mountpoint=legacy`,
mounted by `boot.nix`. `/data2`: ext4 HDD with `nofail`, boot goes on without it.
