---
title: Réinstallation — clochette
description: Guide complet de réinstallation du VPS Scaleway — mode rescue, partitionnement, secrets, vérification.
---

:::caution[Garde]
Guide de réinstallation complète du serveur clochette (VPS Scaleway).

**Avant de commencer** : garder un shell root ouvert pendant toute l'opération.
Ne jamais couper la session active sans avoir vérifié qu'un accès de secours reste disponible.
:::

## Informations de Référence

| Paramètre | Valeur |
|---|---|
| IP publique | `51.159.34.135` |
| Passerelle | `51.159.34.1` |
| DNS | `51.159.47.28`, `51.159.47.26` |
| Disque | `/dev/sda` (BIOS/MBR, pas d'EFI) |
| Architecture | x86_64, Intel KVM |
| SSH public | **Fermé** — accessible uniquement via Tailscale (`100.64.0.0/10`) |

## Pré-Requis

Avant de démarrer :

- [ ] Accès à la console série Scaleway (ou KVM panel)
- [ ] Connexion réseau disponible depuis le serveur
- [ ] Dépôt `nixos` accessible (GitHub ou USB)
- [ ] Clé age de exampleHost disponible (pour re-chiffrer les secrets après install)
      Voir [Sauvegarde & Restauration des Secrets](secrets-backup.md)
- [ ] Sauvegarde Borg vérifiée et récente
      `BORG_PASSPHRASE=... borg list ssh://backup@storage2.friloux.me/~/clochette.friloux.me`
- [ ] DNS d'urgence noté : si Traefik ne redémarre pas, les domaines sont inaccessibles

## Étape 1 — Accès au Mode Rescue Scaleway

Depuis le panel Scaleway :

1. Aller dans **Instances → clochette → Actions → Démarrer en mode rescue**
2. Sélectionner une image rescue (Debian ou Ubuntu)
3. Copier le mot de passe rescue affiché
4. Se connecter en SSH (en mode rescue, SSH public est ouvert) :

```bash
ssh root@51.159.34.135
```

## Étape 2 — Partitionnement du Disque

:::danger[Interdit]
**Destructif.** Toutes les données sur `/dev/sda` sont perdues.
:::

```bash
# Vérifier le disque disponible
lsblk

# Partitionner (MBR/BIOS)
parted /dev/sda --script mklabel msdos
parted /dev/sda --script mkpart primary ext2 1MiB 513MiB    # /boot
parted /dev/sda --script mkpart primary linux-swap 513MiB 4609MiB  # swap
parted /dev/sda --script mkpart primary ext4 4609MiB 100%   # /
```

Formater :

```bash
mkfs.ext2 -L boot /dev/sda1
mkswap -L swap /dev/sda2
mkfs.ext4 -L root /dev/sda3
```

**Noter les UUIDs** — ils seront nécessaires pour mettre à jour `hardware-configuration.nix` :

```bash
blkid /dev/sda1 /dev/sda2 /dev/sda3
```

Exemple de sortie :

```text
/dev/sda1: LABEL="boot" UUID="AAAA-BBBB-..." TYPE="ext2"
/dev/sda2: LABEL="swap" UUID="CCCC-DDDD-..." TYPE="swap"
/dev/sda3: LABEL="root" UUID="EEEE-FFFF-..." TYPE="ext4"
```

## Étape 3 — Monter les Partitions

```bash
mount /dev/sda3 /mnt
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot
swapon /dev/sda2
```

## Étape 4 — Récupérer le Dépôt et Mettre à Jour les UUIDs

```bash
# Installer git dans le rescue (si absent)
apt-get install -y git nix  # ou utiliser le nix du rescue

git clone https://github.com/gfriloux/nixos /tmp/nixos
cd /tmp/nixos
```

Mettre à jour `systems/x86_64-linux/clochette/hardware-configuration.nix` avec les nouveaux UUIDs :

```bash
nano systems/x86_64-linux/clochette/hardware-configuration.nix
```

Remplacer les trois UUIDs :

```nix
fileSystems."/" = {
  device = "/dev/disk/by-uuid/NOUVEAU-UUID-ROOT";  # UUID de /dev/sda3
  fsType = "ext4";
};

fileSystems."/boot" = {
  device = "/dev/disk/by-uuid/NOUVEAU-UUID-BOOT";  # UUID de /dev/sda1
  fsType = "ext2";
};

swapDevices = [
  { device = "/dev/disk/by-uuid/NOUVEAU-UUID-SWAP"; }  # UUID de /dev/sda2
];
```

Committer la modification :

```bash
git config user.email "guillaume@friloux.me"
git config user.name "Guillaume Friloux"
git add systems/x86_64-linux/clochette/hardware-configuration.nix
git commit -m "chore(clochette): update disk UUIDs after reinstall"
```

:::note[Marginalia]
Cette modification peut aussi être faite depuis exampleHost avant l'install si les UUIDs
sont connus à l'avance — et poussée sur GitHub pour que le rescue puisse cloner directement.
:::

## Étape 5 — Installation NixOS

```bash
# Depuis le rescue, avec nix disponible
sudo nixos-install \
  --flake /tmp/nixos#clochette \
  --no-root-passwd \
  --root /mnt
```

L'installation télécharge les paquets et configure le système.
Si une erreur réseau interrompt le téléchargement, relancer la même commande.

## Étape 6 — Premier Démarrage

```bash
reboot
```

Le serveur redémarre sur le système NixOS fraîchement installé.

**Accès post-reboot** : SSH public est fermé par la configuration (`openFirewall = false`,
règle firewall limitée à `100.64.0.0/10`). Utiliser la **console série Scaleway** pour
les étapes suivantes jusqu'à ce que Tailscale soit opérationnel.

## Étape 7 — Ré-enrôlement Tailscale (Console Série)

Depuis la console série Scaleway :

```bash
sudo tailscale up
```

Un lien d'authentification s'affiche. L'ouvrir dans un navigateur, approuver la machine.

Vérifier l'accès :

```bash
tailscale status
# clochette doit apparaître avec une adresse 100.x.x.x
```

Depuis exampleHost, vérifier la connectivité :

```bash
tailscale ping clochette
ssh guillaume@clochette.friloux.me
```

## Étape 8 — Mise à Jour de la Clé Age dans sops

La nouvelle installation a généré une nouvelle clé SSH host, donc une nouvelle clé age.
Sans cette mise à jour, sops ne pourra plus déchiffrer les secrets depuis clochette.

**Depuis clochette** (maintenant accessible via SSH Tailscale) :

```bash
# Obtenir la nouvelle clé age dérivée de la clé SSH host
nix run nixpkgs#ssh-to-age -- -i /etc/ssh/ssh_host_ed25519_key.pub
```

**Depuis exampleHost**, mettre à jour `.sops.yaml` avec la nouvelle clé publique :

```bash
cd ~/Apps/github/gfriloux/nixos  # ou chemin habituel du dépôt
nano .sops.yaml
# Remplacer la valeur de &server_clochette par la nouvelle clé age
```

Re-chiffrer `secrets/clochette.yaml` avec la nouvelle clé :

```bash
sops updatekeys secrets/clochette.yaml
# Confirmer avec 'y'
```

Vérifier que le fichier est bien mis à jour :

```bash
sops -d secrets/clochette.yaml  # doit s'exécuter sans erreur
```

Committer et pousser :

```bash
git add .sops.yaml secrets/clochette.yaml
git commit -m "chore(secrets): rotate clochette age key after reinstall"
git push
```

## Étape 9 — Déploiement Complet depuis exampleHost

```bash
just install_clochette --ask-sudo-password
```

Cette commande déploie la configuration complète, démarre tous les containers
et active la surveillance de santé Docker.

## Étape 10 — Restauration des Données depuis Borg

Si les données des services doivent être restaurées (cas d'une vraie perte) :

```bash
# Se connecter en tant que root sur clochette
ssh guillaume@clochette.friloux.me
sudo -i

# Lister les archives disponibles
BORG_PASSPHRASE=$(cat /run/secrets/services/borg/passphrase) \
BORG_RSH="ssh -i /run/secrets/services/borg/key/private" \
borg list ssh://backup@storage2.friloux.me/~/clochette.friloux.me
```

Exemple de sortie :

```text
clochette-2025-05-16T03:00:01      Fri, 2025-05-16 03:00:05 [...]
clochette-2025-05-15T03:00:01      Thu, 2025-05-15 03:00:04 [...]
```

Restaurer l'archive la plus récente :

```bash
# Arrêter les containers avant restauration
systemctl stop docker-immich-server docker-immich-postgres

# Restaurer (depuis /)
cd /
BORG_PASSPHRASE=$(cat /run/secrets/services/borg/passphrase) \
BORG_RSH="ssh -i /run/secrets/services/borg/key/private" \
borg extract --progress \
  ssh://backup@storage2.friloux.me/~/clochette.friloux.me::clochette-2025-05-16T03:00:01

# Redémarrer les services
systemctl start docker-immich-server docker-immich-postgres
```

## Étape 11 — Vérification Finale

```bash
# Tous les containers sont en cours d'exécution et sains
docker ps --format "table {{.Names}}\t{{.Status}}"

# Santé de chaque container
docker inspect --format='{{.Name}} → {{.State.Health.Status}}' \
  traefik crowdsec immich-server immich-postgres immich-redis

# Certificats Traefik — Let's Encrypt actif
docker exec traefik traefik healthcheck

# Logs récents sans erreur critique
journalctl -u docker-traefik --since "10 minutes ago" | tail -20

# Backup Borg — dernier statut
systemctl status borgbackup-job-remote
```

Vérification externe : accéder depuis un navigateur à :

- `https://photos.friloux.me` (Immich)
