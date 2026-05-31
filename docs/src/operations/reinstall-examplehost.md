# Réinstallation — exampleHost

Guide de réinstallation complète du poste de travail exampleHost.
À lire calmement avant de commencer — certaines étapes sont irréversibles.

## Matériel de référence

| Composant | Détail |
|---|---|
| Disques système | 2× Samsung SSD 980 PRO 1 To NVMe (miroir ZFS) |
| ID disque 0 | `nvme-Samsung_SSD_980_PRO_1TB_S5GXNL0W810368E` |
| ID disque 1 | `nvme-Samsung_SSD_980_PRO_1TB_S5GXNL0W810454N` |
| Disque données | `/dev/disk/by-id/wwn-0x5000c500c78528e7-part1` → `/data2` (ext4, nofail) |
| GPU | AMD (pilote `amdgpu`) |
| hostId ZFS | `21ed29b1` |

> Le disque `/data2` est monté avec `nofail` — son absence ne bloque pas le démarrage.

---

## Pré-requis

Avant de lancer quoi que ce soit, vérifier :

- [ ] La **clé age** de exampleHost est disponible (sauvegarde Bitwarden, USB chiffrée, papier…)
      Voir [Sauvegarde & restauration des secrets](secrets-backup.md)
- [ ] L'ISO NixOS est téléchargée et gravée/flashée
      Utiliser une version récente : <https://nixos.org/download/>
- [ ] Le dépôt git `nixos` est accessible (GitHub ou copie locale sur USB)
- [ ] Une connexion réseau est disponible (filaire recommandé pour l'install)
- [ ] Si `/data2` contient des données importantes : en faire une sauvegarde avant

---

## Résumé du partitionnement

disko crée sur chaque NVMe :

| Partition | Taille | Rôle |
|---|---|---|
| part1 | 1 Go | ESP (vfat) |
| part2 | 4 Go | `bpool` (ZFS, mode grub2) |
| part3 | 920 Go | `rpool` (ZFS) |
| part4 | 4 Go | swap (chiffrement aléatoire) |
| part5 | 1 Mo | GRUB BIOS boot |

Datasets ZFS :

| Dataset | Point de montage |
|---|---|
| `bpool/nixos/root` | `/boot` |
| `rpool/nixos/root` | `/` |
| `rpool/nixos/home` | `/home` |
| `rpool/nixos/var/lib` | `/var/lib` |
| `rpool/nixos/var/log` | `/var/log` |

---

## Étape 1 — Démarrer sur l'ISO NixOS

Flasher l'ISO sur une clé USB :

```bash
# Depuis un autre Linux (remplacer /dev/sdX par le bon périphérique)
sudo dd if=nixos-minimal-*.iso of=/dev/sdX bs=4M conv=fsync status=progress
```

Booter sur la clé USB. Sélectionner l'entrée NixOS dans le menu UEFI.

---

## Étape 2 — Connexion réseau

Si connexion filaire : elle est souvent automatique (DHCP).

Si Wi-Fi nécessaire :

```bash
sudo systemctl start wpa_supplicant
wpa_cli
> add_network 0
> set_network 0 ssid "MonSSID"
> set_network 0 psk "MonMotDePasse"
> enable_network 0
> quit
```

Vérifier la connexion :

```bash
ping -c3 github.com
```

---

## Étape 3 — Récupérer le dépôt flake

```bash
# Cloner le dépôt dans /tmp
git clone https://github.com/gfriloux/nixos /tmp/nixos
cd /tmp/nixos
```

> Si le dépôt est privé ou GitHub inaccessible, brancher une USB contenant
> une copie du dépôt et monter-la :
> ```bash
> mount /dev/sdX1 /mnt/usb
> cp -r /mnt/usb/nixos /tmp/nixos
> ```

---

## Étape 4 — Partitionnement et formatage avec disko

> ⚠️ **Destructif et irréversible.** Cette commande efface entièrement les deux NVMe.
> Les données sur `/data2` (disque séparé) ne sont pas affectées.

```bash
sudo nix run github:nix-community/disko/latest -- \
  --mode destroy,format,mount \
  --flake /tmp/nixos#exampleHost
```

disko va :
1. Effacer et repartitionner les deux Samsung NVMe
2. Créer les pools ZFS `bpool` et `rpool` en miroir
3. Créer les datasets ZFS
4. Formater les partitions ESP (vfat) et swap
5. Monter tout sous `/mnt`

Vérifier que `/mnt` est correctement monté :

```bash
mount | grep /mnt
# Doit afficher rpool/nixos/root, bpool/nixos/root, rpool/nixos/home, etc.

df -h /mnt /mnt/boot /mnt/home /mnt/var/lib /mnt/var/log
```

---

## Étape 5 — Placer la clé age

La clé age doit être présente **avant** l'activation NixOS pour que sops-nix
puisse déchiffrer le mot de passe de l'utilisateur (`neededForUsers = true`).

```bash
sudo mkdir -p /mnt/etc/sops/age
```

Coller le contenu de la clé privée sauvegardée :

```bash
sudo nano /mnt/etc/sops/age/keys.txt
```

Format attendu :

```
# created: 2024-01-01T00:00:00+01:00
# public key: age1xr32hdvanup0zk63v8hrcv2u2c09wplz6fd42w47mkjrd49j39xqaqqckq
AGE-SECRET-KEY-1XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

Corriger les permissions :

```bash
sudo chmod 640 /mnt/etc/sops/age/keys.txt
sudo chown root:root /mnt/etc/sops/age/keys.txt
# (les permissions du groupe seront corrigées par tmpfiles au premier démarrage)
```

Vérifier que la clé publique correspond :

```bash
nix run nixpkgs#age -- -y /mnt/etc/sops/age/keys.txt
# Doit afficher : age1xr32hdvanup0zk63v8hrcv2u2c09wplz6fd42w47mkjrd49j39xqaqqckq
```

Si la clé publique ne correspond pas, **arrêter et vérifier la sauvegarde** avant de continuer.

---

## Étape 6 — Installation NixOS

```bash
sudo nixos-install --flake /tmp/nixos#exampleHost --no-root-passwd
```

L'option `--no-root-passwd` évite de définir un mot de passe root interactif
(le mot de passe de `kuri` est géré par sops).

L'installation prend plusieurs minutes (téléchargement des paquets).
Si une erreur sops apparaît, c'est probablement la clé age — revenir à l'étape 5.

En cas d'erreur réseau en cours de téléchargement, relancer la même commande :
nixos-install reprend là où il s'est arrêté.

---

## Étape 7 — Premier démarrage

```bash
sudo reboot
```

Retirer la clé USB au redémarrage. Le système doit booter sur GRUB → NixOS.

**Si GRUB n'apparaît pas** : vérifier l'ordre de boot dans le BIOS/UEFI.
Chercher une entrée "UEFI OS" ou le nom des Samsung NVMe.

Au premier démarrage, les éléments suivants se lancent automatiquement :
- sddm (écran de connexion Plasma 6)
- Tailscale (démon, pas encore connecté)
- pipewire, NetworkManager, Docker

Se connecter avec l'utilisateur `kuri` et le mot de passe issu de sops.

---

## Étape 8 — Ré-enrôlement Tailscale

Tailscale tourne mais n'est pas encore authentifié.

```bash
sudo tailscale up
```

Un lien d'authentification s'affiche. L'ouvrir dans un navigateur, se connecter
au compte Tailscale, approuver la machine.

Vérifier la connectivité :

```bash
tailscale status
# exampleHost doit apparaître avec une adresse 100.x.x.x

# Tester l'accès à clochette
tailscale ping clochette
```

> Si l'ancienne entrée exampleHost traîne dans l'admin Tailscale avec un état "offline",
> la supprimer depuis <https://login.tailscale.com/admin/machines> avant l'enrôlement.

---

## Étape 9 — Premier déploiement depuis le dépôt

Une fois Tailscale actif et le dépôt cloné sur la machine :

```bash
cd ~/Apps/github/gfriloux/nixos  # ou l'emplacement habituel du dépôt
just install
```

Cette commande (`nh os switch .`) applique la configuration complète et active
Home Manager. Elle est à relancer chaque fois que la config change.

---

## Étape 10 — Vérification finale

```bash
# ZFS pools en bonne santé
zpool status
# Doit afficher ONLINE pour bpool et rpool, aucun error/degraded

# Secrets déchiffrés correctement
ls /run/secrets/
# Doit lister les secrets système (ex: users/kuri/hashed-password)

ls /run/user/1000/secrets/
# Doit lister les secrets Home Manager (rbw_server, workspace...)

# Docker opérationnel
docker info | grep "Storage Driver"
# Doit afficher : Storage Driver: zfs

# Tailscale
tailscale status

# GPU AMD
glxinfo | grep "OpenGL renderer"
# Doit afficher un renderer AMD (ex: AMD Radeon RX...)
```

---

## Cas particulier — remplacement de disques

Si l'un ou les deux Samsung NVMe sont remplacés par de nouveaux modèles,
les IDs dans `systems/x86_64-linux/exampleHost/disko.nix` et `boot.nix`
ne correspondront plus.

**Avant de réinstaller**, mettre à jour les IDs :

```bash
# Depuis l'ISO, identifier les nouveaux disques
ls -la /dev/disk/by-id/ | grep nvme
```

Modifier `disko.nix` et `boot.nix` avec les nouveaux IDs, committer, puis
reprendre à l'étape 4.
