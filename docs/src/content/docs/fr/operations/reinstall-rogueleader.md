---
title: Réinstallation — RogueLeader
description: Guide complet de réinstallation du serveur dédié — disko, secrets, restauration Borg.
---

:::caution[Garde]
Guide de réinstallation complète du serveur dédié domestique RogueLeader.
:::

## Informations de Référence

| Paramètre | Valeur |
|---|---|
| Accès réseau local | `192.168.0.10` (alias `rogueleader.home`) |
| Disque | `/dev/sda` (BIOS/GPT via disko) |
| Architecture | x86_64, Intel KVM |
| SSH | Accessible directement (clé publique uniquement, pas de Tailscale) |
| sops | Clé age dérivée de `/etc/ssh/ssh_host_ed25519_key` |

## Pré-Requis

- [ ] Accès physique ou console au serveur
- [ ] Clé USB NixOS ISO prête
- [ ] Connexion réseau local (DHCP)
- [ ] Clé age de exampleHost disponible (pour re-chiffrer les secrets après install)
      Voir [Sauvegarde & Restauration des Secrets](secrets-backup.md)
- [ ] Sauvegarde Borg vérifiée :
      `BORG_PASSPHRASE=... borg list ssh://backup@storage2.friloux.me/~/rogueleader.friloux.me`

## Résumé du Partitionnement (disko)

Disque unique `/dev/sda`, GPT :

| Partition | Taille | Rôle |
|---|---|---|
| part1 | 1 Mo | GRUB BIOS boot |
| part2 | 4 Go | swap |
| part3 | reste | `/` ext4 |

Contrairement à clochette, disko gère les `fileSystems` NixOS — pas besoin de mettre
à jour des UUIDs manuellement après réinstallation.

## Étape 1 — Démarrer sur l'ISO NixOS

Brancher la clé USB, démarrer sur l'ISO NixOS.

Vérifier la connexion réseau (DHCP LAN) :

```bash
ip addr show
ping -c3 192.168.0.1
```

## Étape 2 — Récupérer le Dépôt

```bash
git clone https://github.com/gfriloux/nixos /tmp/nixos
cd /tmp/nixos
```

## Étape 3 — Partitionnement et Formatage avec disko

:::danger[Interdit]
**Destructif et irréversible.** Efface entièrement `/dev/sda`.
:::

```bash
sudo nix run github:nix-community/disko/latest -- \
  --mode destroy,format,mount \
  --flake /tmp/nixos#RogueLeader
```

disko partitionne `/dev/sda`, formate en ext4 et monte tout sous `/mnt`.

Vérifier :

```bash
df -h /mnt
mount | grep /mnt
```

## Étape 4 — Installation NixOS

```bash
sudo nixos-install --flake /tmp/nixos#RogueLeader --no-root-passwd
```

:::note[Marginalia]
Contrairement à exampleHost, **aucune clé age à placer manuellement** avant l'install.
sops-nix dérive la clé age depuis la clé SSH host générée automatiquement au premier
démarrage — les secrets ne sont déchiffrables qu'après ce premier boot.

En conséquence, le mot de passe utilisateur (`neededForUsers = true`) ne sera
disponible qu'après le premier démarrage complet. L'accès initial se fait par clé SSH.
:::

## Étape 5 — Premier Démarrage

```bash
reboot
```

Retirer la clé USB. Le système démarre sur GRUB → NixOS.

SSH est accessible directement depuis le réseau local via la clé publique déclarée dans `users.nix` :

```bash
# Depuis exampleHost
ssh guillaume@rogueleader.home
```

## Étape 6 — Mise à Jour de la Clé Age dans sops

La nouvelle installation a généré une nouvelle clé SSH host → nouvelle clé age.
Sans cette mise à jour, sops ne pourra pas déchiffrer les secrets depuis RogueLeader.

**Depuis RogueLeader** (connecté via SSH) :

```bash
nix run nixpkgs#ssh-to-age -- -i /etc/ssh/ssh_host_ed25519_key.pub
```

**Depuis exampleHost**, mettre à jour `.sops.yaml` avec la nouvelle clé publique :

```bash
cd ~/Apps/github/gfriloux/nixos
nano .sops.yaml
# Remplacer la valeur de &server_rogueleader par la nouvelle clé age
```

Re-chiffrer `secrets/RogueLeader.yaml` :

```bash
sops updatekeys secrets/RogueLeader.yaml
# Confirmer avec 'y'

# Vérifier
sops -d secrets/RogueLeader.yaml
```

Committer et pousser :

```bash
git add .sops.yaml secrets/RogueLeader.yaml
git commit -m "chore(secrets): rotate RogueLeader age key after reinstall"
git push
```

## Étape 7 — Déploiement Complet depuis exampleHost

```bash
just install_rogueleader --ask-sudo-password
```

Cette commande déploie la configuration complète avec les secrets désormais
déchiffrables par la nouvelle clé SSH host.

Pour déployer Home Manager :

```bash
just home_rogueleader
```

## Étape 8 — Restauration des Données depuis Borg (si Nécessaire)

```bash
# Depuis RogueLeader en root
sudo -i

# Lister les archives
BORG_PASSPHRASE=$(cat /run/secrets/services/borg/passphrase) \
BORG_RSH="ssh -i /run/secrets/services/borg/key/private" \
borg list ssh://backup@storage2.friloux.me/~/rogueleader.friloux.me

# Arrêter les containers
systemctl stop docker-uptime-kuma docker-mealie docker-borg-ui

# Restaurer depuis /
cd /
BORG_PASSPHRASE=$(cat /run/secrets/services/borg/passphrase) \
BORG_RSH="ssh -i /run/secrets/services/borg/key/private" \
borg extract --progress \
  ssh://backup@storage2.friloux.me/~/rogueleader.friloux.me::ARCHIVE_NAME

# Redémarrer les services
systemctl start docker-uptime-kuma docker-mealie docker-borg-ui
```

## Étape 9 — Vérification Finale

```bash
# Containers en cours d'exécution
docker ps --format "table {{.Names}}\t{{.Status}}"

# Secrets déchiffrés
ls /run/secrets/

# Backup Borg
systemctl status borgbackup-job-remote
```
