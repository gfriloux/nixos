---
title: "Reinstall exampleHost"
description: From the NixOS ISO to the first just install, ZFS mirror through disko.
---

:::danger
Step 3 wipes both NVMe drives. `/data2` (separate disk) is not touched.
:::

## Before

- The rescue key copy (the age file), see [Age key backup](/nixos/operations/secrets-backup/).
- A USB stick with the minimal NixOS ISO, network (wired preferred).
- Replaced disks: update their IDs in `disko.nix` **and** `boot.nix`, commit
  (`ls -l /dev/disk/by-id/ | grep nvme` from the ISO).

Expected disks: `nvme-Samsung_SSD_980_PRO_1TB_S5GXNL0W810368E` and `…S5GXNL0W810454N`.
Partitions and datasets: [Storage](/nixos/architecture/storage/).

## 1. Boot the ISO

```bash
sudo dd if=nixos-minimal-*.iso of=/dev/sdX bs=4M conv=fsync status=progress   # from another Linux
```

Wi-Fi if needed: `sudo systemctl start wpa_supplicant`, then `wpa_cli`. Test: `ping -c3 github.com`.

## 2. Get the repository

```bash
git clone https://github.com/gfriloux/nixos /tmp/nixos
```

## 3. Partition (disko)

```bash
sudo nix run github:nix-community/disko/latest -- \
  --mode destroy,format,mount --flake /tmp/nixos#exampleHost
mount | grep /mnt     # rpool/nixos/root, bpool/nixos/root, home, var/lib, var/log
```

## 4. New age key, re-encrypt

Before installing: without it, `kuri`'s password (`neededForUsers`) cannot be decrypted.
The old key is useless, generate a new one. Re-encrypt with the rescue key:
the YubiKey would need `pcscd`, which the ISO lacks.

```bash
sudo mkdir -p /mnt/etc/sops/age
sudo nix shell nixpkgs#age -c age-keygen -o /mnt/etc/sops/age/keys.txt   # prints the public key
sudo chmod 640 /mnt/etc/sops/age/keys.txt                                 # tmpfiles sets root:users at boot

cd /tmp/nixos
nano .sops.yaml           # &desktop_examplehost = the new public key
SOPS_AGE_KEY_FILE=<rescue copy> nix run nixpkgs#sops -- updatekeys secrets/kuri_exampleHost.yaml
```

Put the rescue key back offline.

## 5. Install

```bash
sudo nixos-install --flake /tmp/nixos#exampleHost --no-root-passwd
sudo mkdir -p /mnt/home/kuri && sudo cp -r /tmp/nixos /mnt/home/kuri/nixos   # keeps .sops.yaml and the re-encrypted file, /tmp is gone at reboot
sudo reboot
```

sops error: `.sops.yaml` or `updatekeys` (step 4). Network error: run it again, the install resumes.
No GRUB at boot: it is installed as removable, pick the NVMe in the UEFI menu.

## 6. After the first boot

1. Log in as `kuri` (sops password).
2. Tailscale: [Tailscale re-enrollment](/nixos/operations/tailscale/).
3. Recover the copied repository and commit the new key:

   ```bash
   sudo chown -R kuri:users ~/nixos
   mkdir -p ~/Apps/github/gfriloux && mv ~/nixos ~/Apps/github/gfriloux/nixos
   cd ~/Apps/github/gfriloux/nixos
   git commit -am "sops: new exampleHost age key"
   just install   # also applies Home Manager
   ```

## Check

```bash
zpool status                             # bpool and rpool ONLINE
ls /run/secrets/ /run/user/1000/secrets/ # system and Home Manager secrets
docker info | grep "Storage Driver"      # zfs
tailscale status
```
