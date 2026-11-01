---
title: "Réinstaller RogueLeader"
description: De l'ISO NixOS au premier déploiement, par nixos-anywhere depuis exampleHost.
---

:::danger
L'étape 4 efface le disque de RogueLeader. Les services publiés par son newt
sont coupés jusqu'à la restauration Borg (étape 7).
:::

| | |
|---|---|
| Réseau | DHCP, `192.168.0.10` (`rogueleader.home`) |
| Disque | `/dev/sda`, BIOS, GPT + EF02 (`disko.nix`) |
| sops | clé age dérivée de `/etc/ssh/ssh_host_ed25519_key` |
| SSH | LAN, `guillaume`, clé `root@rogueleader` |

## Avant

- Accès physique (écran, clavier), une clé USB avec l'ISO NixOS minimale.
- La YubiKey (`sops`).
- Une archive Borg récente : [Restaurer depuis Borg](/nixos/fr/operations/restore/).

## 1. Générer la clé hôte

Sans elle, la machine neuve ne lit pas son fichier sops : pas de mot de passe,
pas de sudo, aucun déploiement possible.

```bash
mkdir -p /tmp/rogueleader-extra/etc/ssh
ssh-keygen -q -t ed25519 -N "" -C root@RogueLeader -f /tmp/rogueleader-extra/etc/ssh/ssh_host_ed25519_key
nix shell nixpkgs#ssh-to-age -c ssh-to-age < /tmp/rogueleader-extra/etc/ssh/ssh_host_ed25519_key.pub
ssh-keygen -lf /tmp/rogueleader-extra/etc/ssh/ssh_host_ed25519_key.pub   # empreinte à vérifier à l'étape 5
```

Mettre la clé age dans `&server_rogueleader` (`.sops.yaml`), puis :

```bash
sops updatekeys secrets/RogueLeader.yaml   # YubiKey
```

## 2. Booter l'ISO

Sur la console de RogueLeader :

```bash
passwd                # mot de passe jetable pour l'utilisateur nixos
ip -4 addr            # IP de l'ISO
lsblk                 # le disque interne, pas la clé USB
```

Si le disque interne n'est pas `sda` (la clé USB l'a pris), mettre son nom
dans `disko.nix` le temps de l'installation, puis revenir à `/dev/sda`
(comme pour [skitarii](/nixos/fr/operations/reinstall-skitarii/)).

## 3. Copier la clé

```bash
ssh-copy-id -o PubkeyAuthentication=no -i ~/.ssh/id_ed25519 nixos@<ip-iso>
```

## 4. Installer

L'ISO est déjà NixOS : pas de phase `kexec`. L'utilisateur `nixos` a sudo
sans mot de passe.

```bash
ssh-add ~/.ssh/id_ed25519
nix run github:nix-community/nixos-anywhere -- \
  --flake .#RogueLeader \
  --target-host nixos@<ip-iso> \
  --ssh-option IdentitiesOnly=yes \
  --ssh-option IdentityFile=$HOME/.ssh/id_ed25519.pub \
  --phases disko,install \
  --extra-files /tmp/rogueleader-extra
```

Attendu : `Imported /etc/ssh/ssh_host_ed25519_key as age key`, puis
`### Done! ###`. L'empreinte age doit être celle de `.sops.yaml`.

## 5. Premier boot

Retirer la clé USB, redémarrer. Puis :

```bash
ssh-keygen -R 192.168.0.10
ssh -t rogueleader.home sudo true
```

N'accepter que l'empreinte notée à l'étape 1.

## 6. Déployer

```bash
just install_rogueleader
just home_rogueleader
```

Commiter `.sops.yaml` et `secrets/RogueLeader.yaml`, puis
`rm -r /tmp/rogueleader-extra`.

## 7. Restaurer

Les archives ne contiennent aucune base vivante :

- BookStack : recharger le dump MariaDB,
  [BookStack (RogueLeader)](/nixos/fr/operations/restore/#bookstack-rogueleader).
- Uptime Kuma, Papra, Mealie : remettre les copies de
  `sqlite-snapshots/`,
  [Services SQLite (RogueLeader)](/nixos/fr/operations/restore/#services-sqlite-rogueleader).

## 8. Vérifier

```bash
docker ps --format "table {{.Names}}\t{{.Status}}"   # tout healthy
docker logs newt --tail 20                           # tunnel vers skitarii
systemctl start borgbackup-job-remote && systemctl status borgbackup-job-remote
```

`https://status.friloux.me`, `wow-cp`, `docs`, `cuisine` et `borg-ui`
répondent.
