---
title: Vaults of the Machine-Spirit — Storage & Filesystems
description: ZFS configuration on exampleHost, ext4 on clochette and RogueLeader, backup strategies.
---

The Forge's data is inscribed across three shrines in accordance with the machine-spirit's demands: ZFS mirrors on the workstation, ext4 on the VPS and home-shrine, and the sacred snapshots guard against loss.

## exampleHost — The Mirror Pool

Two Samsung SSD 980 PRO 1 TB NVMe in ZFS mirror.

### Pools

**bpool** (mirror, grub2 mode):

| Dataset | Mountpoint |
|---|---|
| `bpool/nixos/root` | `/boot` |

Options: `ashift=12`, `autotrim=on`, grub2-compatible.

**rpool** (mirror):

| Dataset | Mountpoint |
|---|---|
| `rpool/nixos/root` | `/` |
| `rpool/nixos/home` | `/home` |
| `rpool/nixos/var/lib` | `/var/lib` |
| `rpool/nixos/var/log` | `/var/log` |
| `rpool/backup/storage2` | (zrepl pulls snapshots here) |

Options: `ashift=12`, `autotrim=on`.

All datasets carry `mountpoint = "legacy"` — mounting is orchestrated by `boot.nix`.

### Swap

4 GB per disk, encrypted with random keys (`randomEncryption = true`).

### Data Vault

`/data2`: external HDD mounted as ext4 with `nofail` (absence does not block boot).

### Automatic Tending

```nix
services.zfs.autoScrub.enable = true;
services.zfs.trim.enable = true;
```

### Snapshot Guard (zrepl)

exampleHost pulls snapshots from `storage2.retrohive.fr` into `rpool/backup/storage2`.
Retention: 7 days × 1 day + 3 months × 30 days.

## clochette — The Single Vault

Disks: `/dev/sda`, partitioned MBR:

| Partition | Mountpoint | Filesystem |
|---|---|---|
| `/dev/sda1` | `/boot` | ext2 |
| `/dev/sda2` | swap | — |
| `/dev/sda3` | `/` | ext4 |

Bound daemon data resides in `/srv/docker/` (on `/`).
Daily Borg backup to `storage2.friloux.me`.

## RogueLeader — The Home Vault

Disk: `/dev/sda`, partitioned GPT via disko:

| Partition | Purpose |
|---|---|
| 1 MB | GRUB BIOS boot |
| 4 GB | swap |
| remainder | `/` ext4 |
