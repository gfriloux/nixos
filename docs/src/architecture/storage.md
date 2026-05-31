# Stockage & systèmes de fichiers

## exampleHost — ZFS

Deux Samsung SSD 980 PRO 1 To NVMe en miroir ZFS.

### Pools

**bpool** (miroir, mode grub2) :

| Dataset | Mountpoint |
|---|---|
| `bpool/nixos/root` | `/boot` |

Options : `ashift=12`, `autotrim=on`, compatibilité grub2.

**rpool** (miroir) :

| Dataset | Mountpoint |
|---|---|
| `rpool/nixos/root` | `/` |
| `rpool/nixos/home` | `/home` |
| `rpool/nixos/var/lib` | `/var/lib` |
| `rpool/nixos/var/log` | `/var/log` |
| `rpool/backup/storage2` | (pulls zrepl) |

Options : `ashift=12`, `autotrim=on`.

Tous les datasets ont `mountpoint = "legacy"` — le montage est géré par `boot.nix`.

### Swap

4 Go par disque, chiffrement aléatoire (`randomEncryption = true`).

### Disque données

`/data2` : disque HDD externe monté en ext4 avec `nofail` (l'absence du disque ne bloque pas le démarrage).

### Maintenance automatique

```nix
services.zfs.autoScrub.enable = true;
services.zfs.trim.enable = true;
```

### Backup zrepl

exampleHost tire des snapshots depuis `storage2.retrohive.fr` vers `rpool/backup/storage2`.
Rétention : 7 jours × 1j + 3 mois × 30j.

## clochette — ext4

Disque unique `/dev/sda`, partitionnement MBR :

| Partition | Mountpoint | Filesystem |
|---|---|---|
| `/dev/sda1` | `/boot` | ext2 |
| `/dev/sda2` | swap | — |
| `/dev/sda3` | `/` | ext4 |

Les données des containers sont dans `/srv/docker/` (sur `/`).
Backup Borg quotidien vers `storage2.friloux.me`.

## RogueLeader — ext4

Disque unique `/dev/sda`, partitionnement GPT via disko :

| Partition | Usage |
|---|---|
| 1 Mo | GRUB BIOS boot |
| 4 Go | swap |
| reste | `/` ext4 |
