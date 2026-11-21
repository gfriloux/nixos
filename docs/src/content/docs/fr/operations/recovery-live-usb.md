---
title: "Récupérer sans réinstaller"
description: La machine ne démarre plus. Rollback GRUB d'abord, puis ISO live ou secours, chroot, bootloader.
---

:::caution
Pas encore déroulée de bout en bout (#81). Retirer ce bandeau une fois chaque section jouée.
:::

## 1. Revenir en arrière depuis GRUB

Menu GRUB → **NixOS - All configurations** → la génération précédente. Rien
n'est écrit ; c'est la réponse la moins risquée, à essayer en premier.

Une fois démarré, corriger le dépôt puis `just install`, ou faire de la
génération précédente celle par défaut :

```bash
sudo nixos-rebuild boot --rollback
```

Pas de menu GRUB, ou aucune génération ne démarre : section suivante.

## 2. exampleHost : monter depuis l'ISO

ISO NixOS minimal, la même clé que pour [Réinstaller exampleHost](/nixos/fr/operations/reinstall-examplehost/).
Les datasets sont en `mountpoint=legacy` : l'import ne monte rien, chacun se monte à la main,
la racine d'abord. Agencement : [Stockage](/nixos/fr/architecture/storage/).

```bash
sudo -i
zpool import                          # rpool et bpool listés, tous deux ONLINE
zpool import -f -N -R /mnt rpool      # -N : les datasets reçus par zrepl ne doivent pas se monter sur /mnt
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

Vérifier avant d'aller plus loin :

```bash
findmnt -R /mnt                       # 5 zfs + 2 vfat
ls -l /mnt/etc/sops/age/keys.txt      # la clé age, sur le dataset racine
```

## 3. Chroot et réparation

```bash
nixos-enter --root /mnt
```

| But | Commande, dans le chroot |
|---|---|
| Réinstaller GRUB, même génération | `NIXOS_INSTALL_BOOTLOADER=1 /nix/var/nix/profiles/system/bin/switch-to-configuration boot` |
| Reculer d'une génération | `nix-env -p /nix/var/nix/profiles/system --rollback`, puis la ligne du dessus |
| Construire une config corrigée | `NIXOS_INSTALL_BOOTLOADER=1 nixos-rebuild boot --flake /home/kuri/Apps/github/gfriloux/nixos#exampleHost` |

Jamais de `switch` dans le chroot : il n'y a pas de systemd à qui parler.
`boot` n'écrit que le bootloader, il n'a donc besoin ni de sops ni de la clé age.

## 4. Sortir proprement

```bash
exit
umount -R /mnt
zpool export bpool rpool              # un pool laissé importé demande un import forcé au prochain démarrage
reboot
```

## Serveurs

`/` est en ext4 sur un seul disque, GRUB en mode BIOS. Pas de dépôt sur la
machine : réparer le bootloader ou reculer d'une génération, démarrer, puis
redéployer depuis exampleHost.

| Machine | Secours | Racine |
|---|---|---|
| RogueLeader | ISO NixOS sur clé USB | `/dev/sda3` |
| skitarii | Secours OVH | `/dev/sdb3` (`sdb` en secours, `sda` en démarrage normal) |
| clochette | Secours Dedibox | à trouver avec `lsblk -f` ; `/boot` est une partition ext2 séparée |

Depuis l'ISO NixOS : `mount /dev/sda3 /mnt`, puis la section 3. Depuis un
secours OVH ou Dedibox, pas de `nixos-enter` :

```bash
mount /dev/sdb3 /mnt                  # clochette : monter aussi /boot sur /mnt/boot
for d in dev proc sys; do mount --rbind /$d /mnt/$d; done
chroot /mnt /nix/var/nix/profiles/system/activate
chroot /mnt /run/current-system/sw/bin/bash
```

Puis les deux premières lignes du tableau de la section 3. Sortir avec `exit`,
`umount -R /mnt`, et repasser la console en démarrage normal.
