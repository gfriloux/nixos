---
title: Rite of Resurrection — clochette
description: Complete reinstallation guide for the VPS on Scaleway with Traefik and bound daemons.
---

Complete guide to resurrect the clochette VPS.

:::caution[Ward]
Keep a root shell open throughout. Never close the active session without verifying fallback access remains.
:::

## Reference Information

| Parameter | Value |
|---|---|
| Public IP | `51.159.34.135` |
| Gateway | `51.159.34.1` |
| DNS | `51.159.47.28`, `51.159.47.26` |
| Disk | `/dev/sda` (BIOS/MBR, no EFI) |
| Architecture | x86_64, Intel KVM |
| SSH public | **Closed** — accessible only via Tailscale (`100.64.0.0/10`) |

## Prerequisites

Before starting:

- [ ] Access to Scaleway serial console (or KVM panel)
- [ ] Network connectivity from the server
- [ ] `nixos` repo accessible (GitHub or USB)
- [ ] exampleHost age key available (for re-encrypting secrets after install)
      See [Reliquary Backup & Restoration](secrets-backup.md)
- [ ] Recent Borg backup verified
      `BORG_PASSPHRASE=... borg list ssh://backup@storage2.friloux.me/~/clochette.friloux.me`
- [ ] Emergency DNS noted: if Traefik fails to restart, domains are unreachable

## Step 1 — Access Scaleway Rescue Mode

From the Scaleway panel:

1. Go to **Instances → clochette → Actions → Start in rescue mode**
2. Select a rescue image (Debian or Ubuntu)
3. Copy the displayed rescue password
4. SSH (in rescue mode, public SSH is open):

```bash
ssh root@51.159.34.135
```

## Step 2 — Disk Partitioning

:::danger[Interdict]
Destructive. All data on `/dev/sda` is lost.
:::

```bash
# Verify available disk
lsblk

# Partition (MBR/BIOS)
parted /dev/sda --script mklabel msdos
parted /dev/sda --script mkpart primary ext2 1MiB 513MiB    # /boot
parted /dev/sda --script mkpart primary linux-swap 513MiB 4609MiB  # swap
parted /dev/sda --script mkpart primary ext4 4609MiB 100%   # /
```

Format:

```bash
mkfs.ext2 -L boot /dev/sda1
mkswap -L swap /dev/sda2
mkfs.ext4 -L root /dev/sda3
```

**Note the UUIDs** — needed to update `hardware-configuration.nix`:

```bash
blkid /dev/sda1 /dev/sda2 /dev/sda3
```

Example output:

```
/dev/sda1: LABEL="boot" UUID="AAAA-BBBB-..." TYPE="ext2"
/dev/sda2: LABEL="swap" UUID="CCCC-DDDD-..." TYPE="swap"
/dev/sda3: LABEL="root" UUID="EEEE-FFFF-..." TYPE="ext4"
```

## Step 3 — Mount Partitions

```bash
mount /dev/sda3 /mnt
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot
swapon /dev/sda2
```

## Step 4 — Fetch Repository and Update UUIDs

```bash
# Install git if missing in rescue
apt-get install -y git nix

git clone https://github.com/gfriloux/nixos /tmp/nixos
cd /tmp/nixos
```

Update `systems/x86_64-linux/clochette/hardware-configuration.nix` with the new UUIDs:

```bash
nano systems/x86_64-linux/clochette/hardware-configuration.nix
```

Replace the three UUIDs:

```nix
fileSystems."/" = {
  device = "/dev/disk/by-uuid/NEW-UUID-ROOT";  # UUID from /dev/sda3
  fsType = "ext4";
};

fileSystems."/boot" = {
  device = "/dev/disk/by-uuid/NEW-UUID-BOOT";  # UUID from /dev/sda1
  fsType = "ext2";
};

swapDevices = [
  { device = "/dev/disk/by-uuid/NEW-UUID-SWAP"; }  # UUID from /dev/sda2
];
```

Commit:

```bash
git config user.email "guillaume@friloux.me"
git config user.name "Guillaume Friloux"
git add systems/x86_64-linux/clochette/hardware-configuration.nix
git commit -m "chore(clochette): update disk UUIDs after reinstall"
```

(This change can also be made from exampleHost beforehand if UUIDs are known,
pushed to GitHub for the rescue to clone directly.)

## Step 5 — NixOS Installation

```bash
# From rescue, with nix available
sudo nixos-install \
  --flake /tmp/nixos#clochette \
  --no-root-passwd \
  --root /mnt
```

The install downloads packages and configures the system.
If network error interrupts the download, re-run the same command.

## Step 6 — First Boot

```bash
reboot
```

The server reboots into the freshly installed NixOS.

**Post-reboot access**: Public SSH is closed by config (`openFirewall = false`,
firewall rule limited to `100.64.0.0/10`). Use the **Scaleway serial console** for
the next steps until Tailscale is operational.

## Step 7 — Tailscale Re-enrollment (Serial Console)

From the Scaleway serial console:

```bash
sudo tailscale up
```

An authentication link appears. Open it in a browser, approve the machine.

Verify access:

```bash
tailscale status
# clochette should appear with a 100.x.x.x address
```

From exampleHost, verify connectivity:

```bash
tailscale ping clochette
ssh guillaume@clochette.friloux.me
```

## Step 8 — Update Age Key in sops

The new install generated a new SSH host key, thus a new age key.
Without this update, sops cannot decrypt secrets from clochette.

**From clochette** (now accessible via Tailscale SSH):

```bash
# Get the new age key derived from the SSH host key
nix run nixpkgs#ssh-to-age -- -i /etc/ssh/ssh_host_ed25519_key.pub
```

**From exampleHost**, update `.sops.yaml` with the new public key:

```bash
cd ~/Apps/github/gfriloux/nixos
nano .sops.yaml
# Replace &server_clochette value with the new age key
```

Re-encrypt `secrets/clochette.yaml` with the new key:

```bash
sops updatekeys secrets/clochette.yaml
# Confirm with 'y'
```

Verify the file is updated:

```bash
sops -d secrets/clochette.yaml  # must execute without error
```

Commit and push:

```bash
git add .sops.yaml secrets/clochette.yaml
git commit -m "chore(secrets): rotate clochette age key after reinstall"
git push
```

## Step 9 — Full Deployment from exampleHost

```bash
just install_clochette --ask-sudo-password
```

This deploys the complete configuration, starts all bound daemons,
and activates Docker health watch.

## Step 10 — Data Restoration from Borg

If service data must be restored (real loss scenario):

```bash
# SSH as root to clochette
ssh guillaume@clochette.friloux.me
sudo -i

# List available archives
BORG_PASSPHRASE=$(cat /run/secrets/services/borg/passphrase) \
BORG_RSH="ssh -i /run/secrets/services/borg/key/private" \
borg list ssh://backup@storage2.friloux.me/~/clochette.friloux.me
```

Example output:

```
clochette-2025-05-16T03:00:01      Fri, 2025-05-16 03:00:05 [...]
clochette-2025-05-15T03:00:01      Thu, 2025-05-15 03:00:04 [...]
```

Restore the most recent archive:

```bash
# Stop daemons before restoration
systemctl stop docker-papra docker-wow-cp-bookstack docker-wow-cp-mariadb \
                docker-immich-server docker-immich-postgres

# Restore (from /)
cd /
BORG_PASSPHRASE=$(cat /run/secrets/services/borg/passphrase) \
BORG_RSH="ssh -i /run/secrets/services/borg/key/private" \
borg extract --progress \
  ssh://backup@storage2.friloux.me/~/clochette.friloux.me::clochette-2025-05-16T03:00:01

# Restart services
systemctl start docker-papra docker-wow-cp-bookstack docker-wow-cp-mariadb \
                docker-immich-server docker-immich-postgres
```

## Step 11 — Final Verification

```bash
# All daemons are running and healthy
docker ps --format "table {{.Names}}\t{{.Status}}"

# Health of each daemon
docker inspect --format='{{.Name}} → {{.State.Health.Status}}' \
  traefik crowdsec papra wow-cp-bookstack wow-cp-mariadb immich-server immich-postgres

# Traefik certificates — Let's Encrypt active
docker exec traefik traefik healthcheck

# Recent logs without critical errors
journalctl -u docker-traefik --since "10 minutes ago" | tail -20

# Borg backup — latest status
systemctl status borgbackup-job-remote
```

Verify externally: access from a browser:
- `https://docs.friloux.me` (Papra)
- `https://wow-cp.friloux.me` (BookStack)
- `https://photos.friloux.me` (Immich)
