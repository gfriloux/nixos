---
title: "Réinstaller exampleHost"
description: De l'ISO NixOS au premier just install, miroir ZFS par disko.
---

:::danger
L'étape 3 efface les deux NVMe. `/data2` (disque séparé) n'est pas touché.
:::

## Avant

- La copie de la clé de secours (le fichier age), voir [Sauvegarde des clés age](/nixos/fr/operations/secrets-backup/).
- Une clé USB avec l'ISO NixOS minimale, du réseau (filaire de préférence).
- Disques remplacés : mettre à jour leurs IDs dans `disko.nix` **et** `boot.nix`, committer
  (`ls -l /dev/disk/by-id/ | grep nvme` depuis l'ISO).

Disques attendus : `nvme-Samsung_SSD_980_PRO_1TB_S5GXNL0W810368E` et `…S5GXNL0W810454N`.
Partitions et datasets : [Stockage](/nixos/fr/architecture/storage/).

## 1. Booter l'ISO

```bash
sudo dd if=nixos-minimal-*.iso of=/dev/sdX bs=4M conv=fsync status=progress   # depuis un autre Linux
```

Wi-Fi si besoin : `sudo systemctl start wpa_supplicant`, puis `wpa_cli`. Tester : `ping -c3 github.com`.

## 2. Récupérer le dépôt

```bash
git clone https://github.com/gfriloux/nixos /tmp/nixos
```

## 3. Partitionner (disko)

```bash
sudo nix run github:nix-community/disko/latest -- \
  --mode destroy,format,mount --flake /tmp/nixos#exampleHost
mount | grep /mnt     # rpool/nixos/root, bpool/nixos/root, home, var/lib, var/log
```

## 4. Nouvelle clé age, rechiffrer

Avant l'install : sans elle, le mot de passe de `kuri` (`neededForUsers`) ne se déchiffre pas.
L'ancienne clé ne sert plus, on en génère une. Le rechiffrement se fait avec la clé de secours :
la YubiKey demanderait `pcscd`, absent de l'ISO.

```bash
sudo mkdir -p /mnt/etc/sops/age
sudo nix shell nixpkgs#age -c age-keygen -o /mnt/etc/sops/age/keys.txt   # affiche la clé publique
sudo chmod 640 /mnt/etc/sops/age/keys.txt                                 # tmpfiles remet root:users au boot

cd /tmp/nixos
nano .sops.yaml           # &desktop_examplehost = la nouvelle clé publique
SOPS_AGE_KEY_FILE=<copie de secours> nix run nixpkgs#sops -- updatekeys secrets/kuri_exampleHost.yaml
```

Remettre la clé de secours hors ligne.

## 5. Installer

```bash
sudo nixos-install --flake /tmp/nixos#exampleHost --no-root-passwd
sudo mkdir -p /mnt/home/kuri && sudo cp -r /tmp/nixos /mnt/home/kuri/nixos   # garde .sops.yaml et le fichier rechiffré, /tmp disparaît au reboot
sudo reboot
```

Erreur sops : `.sops.yaml` ou `updatekeys` (étape 4). Erreur réseau : relancer, l'install reprend.
GRUB absent au boot : il est installé en mode amovible, choisir le NVMe dans le menu UEFI.

## 6. Après le premier boot

1. Se connecter en `kuri` (mot de passe sops).
2. Tailscale : [Ré-enrôlement Tailscale](/nixos/fr/operations/tailscale/).
3. Récupérer le dépôt copié et commiter la nouvelle clé :

   ```bash
   sudo chown -R kuri:users ~/nixos
   mkdir -p ~/Apps/github/gfriloux && mv ~/nixos ~/Apps/github/gfriloux/nixos
   cd ~/Apps/github/gfriloux/nixos
   git commit -am "sops: new exampleHost age key"
   just install   # applique aussi Home Manager
   ```

## Vérifier

```bash
zpool status                             # bpool et rpool ONLINE
ls /run/secrets/ /run/user/1000/secrets/ # secrets système et Home Manager
docker info | grep "Storage Driver"      # zfs
tailscale status
```
