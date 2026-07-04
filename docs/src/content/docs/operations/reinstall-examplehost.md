---
title: Rite of Resurrection — exampleHost
description: Complete reinstallation guide for the workstation-shrine with ZFS mirrors and AMD GPU.
---

Complete guide to resurrect exampleHost from the ashes.
Read this calmly before beginning — some steps are irreversible.

:::caution[Ward]
This rite is irreversible at certain steps. Execute each command exactly as written.
:::

## Hardware Reference

| Component | Detail |
|---|---|
| System disks | 2× Samsung SSD 980 PRO 1 TB NVMe (ZFS mirror) |
| ID disk 0 | `nvme-Samsung_SSD_980_PRO_1TB_S5GXNL0W810368E` |
| ID disk 1 | `nvme-Samsung_SSD_980_PRO_1TB_S5GXNL0W810454N` |
| Data disk | `/dev/disk/by-id/wwn-0x5000c500c78528e7-part1` → `/data2` (ext4, nofail) |
| GPU | AMD (driver `amdgpu`) |
| ZFS hostId | `21ed29b1` |

Note: `/data2` is mounted with `nofail` — its absence does not block boot.

## Prerequisites

Before proceeding:

- [ ] The exampleHost age key is available (Bitwarden, encrypted USB, paper backup…)
      See [Reliquary Backup & Restoration](secrets-backup.md)
- [ ] NixOS ISO is downloaded and burned/flashed
      Use a recent version: <https://nixos.org/download/>
- [ ] The `nixos` git repo is accessible (GitHub or USB copy)
- [ ] Network connection available (wired recommended for install)
- [ ] If `/data2` contains important data: back it up first

## Partitioning Summary

disko creates on each NVMe:

| Partition | Size | Role |
|---|---|---|
| part1 | 1 GB | ESP (vfat) |
| part2 | 4 GB | `bpool` (ZFS, grub2 mode) |
| part3 | 920 GB | `rpool` (ZFS) |
| part4 | 4 GB | swap (random encryption) |
| part5 | 1 MB | GRUB BIOS boot |

ZFS datasets:

| Dataset | Mountpoint |
|---|---|
| `bpool/nixos/root` | `/boot` |
| `rpool/nixos/root` | `/` |
| `rpool/nixos/home` | `/home` |
| `rpool/nixos/var/lib` | `/var/lib` |
| `rpool/nixos/var/log` | `/var/log` |

## Step 1 — Boot on NixOS ISO

Flash the ISO to USB:

```bash
# From another Linux (replace /dev/sdX with correct device)
sudo dd if=nixos-minimal-*.iso of=/dev/sdX bs=4M conv=fsync status=progress
```

Boot from USB. Select NixOS in UEFI menu.

## Step 2 — Network Connection

If wired: often automatic (DHCP).

If Wi-Fi needed:

```bash
sudo systemctl start wpa_supplicant
wpa_cli
> add_network 0
> set_network 0 ssid "MySSID"
> set_network 0 psk "MyPassword"
> enable_network 0
> quit
```

Verify:

```bash
ping -c3 github.com
```

## Step 3 — Fetch the Flake Repository

```bash
# Clone into /tmp
git clone https://github.com/gfriloux/nixos /tmp/nixos
cd /tmp/nixos
```

If the repo is private or GitHub is unreachable, mount a USB with a repo copy:

```bash
mount /dev/sdX1 /mnt/usb
cp -r /mnt/usb/nixos /tmp/nixos
```

## Step 4 — Disk Partitioning with disko

:::danger[Interdict]
Destructive and irreversible. This command erases both NVMe entirely.
Data on `/data2` (separate disk) is not affected.
:::

```bash
sudo nix run github:nix-community/disko/latest -- \
  --mode destroy,format,mount \
  --flake /tmp/nixos#exampleHost
```

disko will:

1. Erase and repartition both Samsung NVMe
2. Create ZFS pools `bpool` and `rpool` in mirror
3. Create ZFS datasets
4. Format ESP (vfat) and swap partitions
5. Mount everything under `/mnt`

Verify `/mnt` is correctly mounted:

```bash
mount | grep /mnt
# Should display rpool/nixos/root, bpool/nixos/root, etc.

df -h /mnt /mnt/boot /mnt/home /mnt/var/lib /mnt/var/log
```

## Step 5 — Place the Age Key

The age key must be present **before** NixOS activation for sops-nix
to decrypt user passwords (`neededForUsers = true`).

```bash
sudo mkdir -p /mnt/etc/sops/age
```

Paste the saved private key content:

```bash
sudo nano /mnt/etc/sops/age/keys.txt
```

Expected format:

```text
# created: 2024-01-01T00:00:00+01:00
# public key: age1xr32hdvanup0zk63v8hrcv2u2c09wplz6fd42w47mkjrd49j39xqaqqckq
AGE-SECRET-KEY-1XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

Correct permissions:

```bash
sudo chmod 640 /mnt/etc/sops/age/keys.txt
sudo chown root:root /mnt/etc/sops/age/keys.txt
# (tmpfiles will correct group perms on first boot)
```

Verify the public key matches:

```bash
nix run nixpkgs#age -- -y /mnt/etc/sops/age/keys.txt
# Must display: age1xr32hdvanup0zk63v8hrcv2u2c09wplz6fd42w47mkjrd49j39xqaqqckq
```

If the public key does not match, **stop and verify the backup** before proceeding.

## Step 6 — NixOS Installation

```bash
sudo nixos-install --flake /tmp/nixos#exampleHost --no-root-passwd
```

The `--no-root-passwd` option avoids interactive root password setup
(the `kuri` password is managed by sops).

Installation takes several minutes (package download).
If a sops error appears, it is likely the age key — return to step 5.

If network error interrupts the download, re-run the same command:
nixos-install resumes where it stopped.

## Step 7 — First Boot

```bash
sudo reboot
```

Remove the USB at restart. System should boot into GRUB → NixOS.

**If GRUB does not appear**: verify boot order in BIOS/UEFI.
Look for "UEFI OS" or the Samsung NVMe names.

At first boot, these start automatically:

- sddm (Plasma 6 login screen)
- Tailscale (daemon, not yet connected)
- pipewire, NetworkManager, Docker

Log in with user `kuri` and the password from sops.

## Step 8 — Tailscale Re-enrollment

Tailscale is running but not yet authenticated.

```bash
sudo tailscale up
```

An authentication link appears. Open it in a browser, log into Tailscale, approve the machine.

Verify connectivity:

```bash
tailscale status
# exampleHost should appear with a 100.x.x.x address

# Test access to clochette
tailscale ping clochette
```

If the old exampleHost entry remains in Tailscale admin with "offline" state,
delete it from <https://login.tailscale.com/admin/machines> before re-enrollment.

## Step 9 — First Deployment from Repository

Once Tailscale is active and the repo is cloned on the machine:

```bash
cd ~/Apps/github/gfriloux/nixos  # or wherever the repo lives
just install
```

This (`nh os switch .`) applies the complete configuration and activates Home Manager.
Re-run it whenever the config changes.

## Step 10 — Final Verification

```bash
# ZFS pools are healthy
zpool status
# Should display ONLINE for bpool and rpool, no errors/degraded

# Secrets decrypted correctly
ls /run/secrets/
# Should list system secrets (e.g., users/kuri/hashed-password)

ls /run/user/1000/secrets/
# Should list HM secrets (rbw_server, workspace...)

# Docker operational
docker info | grep "Storage Driver"
# Should display: Storage Driver: zfs

# Tailscale
tailscale status

# AMD GPU
glxinfo | grep "OpenGL renderer"
# Should display an AMD renderer (e.g., AMD Radeon RX...)
```

## Special Case — Disk Replacement

If one or both Samsung NVMe are replaced with new models,
the IDs in `systems/x86_64-linux/exampleHost/disko.nix` and `boot.nix`
will no longer match.

**Before reinstalling**, update the IDs:

```bash
# From ISO, identify new disks
ls -la /dev/disk/by-id/ | grep nvme
```

Update `disko.nix` and `boot.nix` with the new IDs, commit, then
resume at step 4.
