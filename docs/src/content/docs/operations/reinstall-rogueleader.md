---
title: Rite of Resurrection — RogueLeader
description: Complete reinstallation guide for the domestic dedicated server.
---

Complete guide to resurrect the RogueLeader home-shrine.

:::caution[Ward]
This rite is irreversible at certain steps. Execute each command exactly as written.
:::

## Reference Information

| Parameter | Value |
|---|---|
| Local network | `192.168.0.10` (alias `rogueleader.home`) |
| Disk | `/dev/sda` (BIOS/GPT via disko) |
| Architecture | x86_64, Intel KVM |
| SSH | Directly accessible (public key only, no Tailscale) |
| sops | Age key derived from `/etc/ssh/ssh_host_ed25519_key` |

## Prerequisites

- [ ] Physical or console access to the server
- [ ] NixOS ISO USB ready
- [ ] Local network connectivity (DHCP)
- [ ] exampleHost age key available (for re-encrypting secrets after install)
      See [Reliquary Backup & Restoration](secrets-backup.md)
- [ ] Recent Borg backup verified:
      `BORG_PASSPHRASE=... borg list ssh://backup@storage2.friloux.me/~/rogueleader.friloux.me`

## Partitioning Summary (disko)

Single disk `/dev/sda`, GPT:

| Partition | Size | Role |
|---|---|---|
| part1 | 1 MB | GRUB BIOS boot |
| part2 | 4 GB | swap |
| part3 | remainder | `/` ext4 |

Unlike clochette, disko manages the NixOS `fileSystems` — no manual UUID updates needed after reinstall.

## Step 1 — Boot on NixOS ISO

Plug in USB, boot from NixOS ISO.

Verify network connectivity (DHCP LAN):

```bash
ip addr show
ping -c3 192.168.0.1
```

## Step 2 — Fetch Repository

```bash
git clone https://github.com/gfriloux/nixos /tmp/nixos
cd /tmp/nixos
```

## Step 3 — Disk Partitioning with disko

:::danger[Interdict]
Destructive and irreversible. Erases `/dev/sda` entirely.
:::

```bash
sudo nix run github:nix-community/disko/latest -- \
  --mode destroy,format,mount \
  --flake /tmp/nixos#RogueLeader
```

disko partitions `/dev/sda`, formats as ext4, and mounts everything under `/mnt`.

Verify:

```bash
df -h /mnt
mount | grep /mnt
```

## Step 4 — NixOS Installation

```bash
sudo nixos-install --flake /tmp/nixos#RogueLeader --no-root-passwd
```

:::note[Marginalia]
Unlike exampleHost, **no age key to place manually** before install.
sops-nix derives the age key from the SSH host key auto-generated at first boot — secrets are only decryptable after the first complete boot.

Consequently, the user password (`neededForUsers = true`) is only available after first boot completes. Initial access is via SSH key.
:::

## Step 5 — First Boot

```bash
reboot
```

Remove the USB. System boots into GRUB → NixOS.

SSH is directly accessible from the local network via the public key declared in `users.nix`:

```bash
# From exampleHost
ssh guillaume@rogueleader.home
```

## Step 6 — Update Age Key in sops

The new install generated a new SSH host key → new age key.
Without this update, sops cannot decrypt secrets from RogueLeader.

**From RogueLeader** (connected via SSH):

```bash
nix run nixpkgs#ssh-to-age -- -i /etc/ssh/ssh_host_ed25519_key.pub
```

**From exampleHost**, update `.sops.yaml` with the new public key:

```bash
cd ~/Apps/github/gfriloux/nixos
nano .sops.yaml
# Replace &server_rogueleader value with the new age key
```

Re-encrypt `secrets/RogueLeader.yaml`:

```bash
sops updatekeys secrets/RogueLeader.yaml
# Confirm with 'y'

# Verify
sops -d secrets/RogueLeader.yaml
```

Commit and push:

```bash
git add .sops.yaml secrets/RogueLeader.yaml
git commit -m "chore(secrets): rotate RogueLeader age key after reinstall"
git push
```

## Step 7 — Full Deployment from exampleHost

```bash
just install_rogueleader --ask-sudo-password
```

This deploys the complete configuration with secrets now decryptable by the new SSH host key.

To deploy Home Manager:

```bash
just home_rogueleader
```

## Step 8 — Data Restoration from Borg (if needed)

```bash
# From RogueLeader as root
sudo -i

# List archives
BORG_PASSPHRASE=$(cat /run/secrets/services/borg/passphrase) \
BORG_RSH="ssh -i /run/secrets/services/borg/key/private" \
borg list ssh://backup@storage2.friloux.me/~/rogueleader.friloux.me

# Stop daemons
systemctl stop docker-papra docker-uptime-kuma docker-mealie docker-borg-ui \
                docker-wow-cp-bookstack docker-wow-cp-mariadb docker-wow-cp-mysqldump

# Restore from /
cd /
BORG_PASSPHRASE=$(cat /run/secrets/services/borg/passphrase) \
BORG_RSH="ssh -i /run/secrets/services/borg/key/private" \
borg extract --progress \
  ssh://backup@storage2.friloux.me/~/rogueleader.friloux.me::ARCHIVE_NAME

# Restart services
systemctl start docker-papra docker-uptime-kuma docker-mealie docker-borg-ui \
                docker-wow-cp-bookstack docker-wow-cp-mariadb docker-wow-cp-mysqldump
```

## Step 9 — Final Verification

```bash
# Daemons are running
docker ps --format "table {{.Names}}\t{{.Status}}"

# Secrets decrypted
ls /run/secrets/

# Borg backup
systemctl status borgbackup-job-remote
```
