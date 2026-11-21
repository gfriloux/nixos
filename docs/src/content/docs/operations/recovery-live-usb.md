---
title: "Recover without reinstalling"
description: The machine no longer boots. GRUB rollback first, then live ISO or rescue, chroot, bootloader.
---

:::caution
Not run end to end yet (#81). Remove this notice once each section has been played.
:::

## 1. Roll back from GRUB

GRUB menu → **NixOS - All configurations** → the previous generation. Nothing
is written; it is the least risky answer, try it first.

Once booted, fix the repository and `just install`, or make the previous
generation the default:

```bash
sudo nixos-rebuild boot --rollback
```

No GRUB menu at all, or no generation boots: next section.

## 2. exampleHost: mount from the ISO

Minimal NixOS ISO, same stick as [Reinstall exampleHost](/nixos/operations/reinstall-examplehost/).
Datasets are `mountpoint=legacy`: importing mounts nothing, each one is mounted by hand,
root first. Layout: [Storage](/nixos/architecture/storage/).

```bash
sudo -i
zpool import                          # rpool and bpool listed, both ONLINE
zpool import -f -N -R /mnt rpool      # -N: zrepl's received datasets must not mount over /mnt
zpool import -f -N -R /mnt bpool

mount -t zfs rpool/nixos/root    /mnt
mount -t zfs bpool/nixos/root    /mnt/boot
mount -t zfs rpool/nixos/home    /mnt/home
mount -t zfs rpool/nixos/var/lib /mnt/var/lib
mount -t zfs rpool/nixos/var/log /mnt/var/log

for d in /dev/disk/by-id/nvme-Samsung_SSD_980_PRO_1TB_*-part1; do
  mount -o X-mount.mkdir "$d" "/mnt/boot/efis/$(basename "$d")"
done
```

Check before going further:

```bash
findmnt -R /mnt                       # 5 zfs + 2 vfat
ls -l /mnt/etc/sops/age/keys.txt      # the age key, on the root dataset
```

## 3. Chroot and repair

```bash
nixos-enter --root /mnt
```

| Goal | Command, inside the chroot |
|---|---|
| Reinstall GRUB, same generation | `NIXOS_INSTALL_BOOTLOADER=1 /nix/var/nix/profiles/system/bin/switch-to-configuration boot` |
| Go back one generation | `nix-env -p /nix/var/nix/profiles/system --rollback`, then the line above |
| Build a fixed config | `NIXOS_INSTALL_BOOTLOADER=1 nixos-rebuild boot --flake /home/kuri/Apps/github/gfriloux/nixos#exampleHost` |

Never `switch` in the chroot: there is no systemd to talk to. `boot` only
writes the bootloader, so it needs neither sops nor the age key.

## 4. Leave cleanly

```bash
exit
umount -R /mnt
zpool export bpool rpool              # a pool left imported needs a forced import at next boot
reboot
```

## Servers

`/` is ext4 on one disk, GRUB in BIOS mode. No repository on the box: repair
the bootloader or roll back, boot, then redeploy from exampleHost.

| Machine | Rescue | Root |
|---|---|---|
| RogueLeader | NixOS ISO on a USB stick | `/dev/sda3` |
| skitarii | OVH rescue | `/dev/sdb3` (`sdb` in rescue, `sda` in normal boot) |
| clochette | Dedibox rescue | find it with `lsblk -f`; `/boot` is a separate ext2 partition |

From the NixOS ISO: `mount /dev/sda3 /mnt`, then section 3. From an OVH or
Dedibox rescue there is no `nixos-enter`:

```bash
mount /dev/sdb3 /mnt                  # clochette: also mount /boot on /mnt/boot
for d in dev proc sys; do mount --rbind /$d /mnt/$d; done
chroot /mnt /nix/var/nix/profiles/system/activate
chroot /mnt /run/current-system/sw/bin/bash
```

Then the first two rows of the table in section 3. Leave with `exit`,
`umount -R /mnt`, and switch the console back to normal boot.
