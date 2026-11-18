---
title: "Clé age compromise"
description: Une clé que quelqu'un d'autre détient peut-être. La remplacer, rechiffrer les fichiers, changer chaque secret qu'elle pouvait lire.
---

Une clé perdue se remplace : [Sauvegarde des clés age](/nixos/fr/operations/secrets-backup/#clé-perdue).
Une clé que quelqu'un d'autre détient peut-être, c'est autre chose. Le dépôt
est public : chaque ancienne version des fichiers sops reste lisible avec cette
clé, quoi qu'on fasse ensuite. Remplacer la clé ne suffit pas, **chaque secret
qu'elle pouvait ouvrir doit changer**.

## Périmètre

| Clé en doute | Fichiers qu'elle ouvre |
|---|---|
| YubiKey ou clé de secours | les quatre |
| Clé de boot d'exampleHost | `secrets/kuri_exampleHost.yaml` |
| Clé hôte d'un serveur | le fichier de ce serveur |

```bash
grep -c 'ENC\[' secrets/*.yaml    # valeurs par fichier : 65 en tout le 2026-11-18
```

- **Clé de secours** : un simple fichier, copié sans laisser de trace.
- **YubiKey** : la clé ne peut pas être extraite. En doute seulement si
  quelqu'un a eu le jeton en main et connaissait le PIN PIV.
- **Clé hôte** : celui qui l'a lue était root sur la machine. Traiter la
  machine comme compromise elle aussi, pas seulement son fichier.

## 1. Remplacer la clé

Clé de secours, puis la clé publique va dans `&admin_rescue` (`.sops.yaml`) :

```bash
age-keygen -o /tmp/rescue-new.txt    # affiche la clé publique
```

YubiKey, puis le destinataire va dans `&admin_yubikey` :

```bash
age-plugin-yubikey --generate --slot 1 --name sops-master --force
age-plugin-yubikey --identity --slot 1 > ~/.config/sops/age/keys.txt
```

`--force` détruit l'ancienne identité : dès lors seule la clé de secours ouvre
les fichiers, donc la vérifier avant ([Vérifier](/nixos/fr/operations/secrets-backup/#vérifier)).

Clé de boot ou clé hôte : même remède que pour une
[clé perdue](/nixos/fr/operations/secrets-backup/#clé-perdue), puis les étapes
2 à 4 sur ce seul fichier.

## 2. Rechiffrer les fichiers

Avec la clé d'admin qui n'est pas en doute :

```bash
sops updatekeys -y secrets/*.yaml
sops rotate -i secrets/kuri_exampleHost.yaml
sops rotate -i secrets/clochette.yaml
sops rotate -i secrets/RogueLeader.yaml
sops rotate -i secrets/skitarii.yaml
```

`updatekeys` change les destinataires et garde la clé de données. `rotate` en
tire une nouvelle : sans lui, une clé de données déjà extraite ouvre encore le
fichier.

## 3. Changer chaque secret

Les noms des clés sont en clair dans les fichiers. Nouvelle valeur à la source,
puis `sops secrets/<fichier>.yaml`.

| Secret | Nouvelle valeur depuis |
|---|---|
| `users/*/hashed-password` | `mkpasswd` |
| Clés SSH (`ssh/keys/*`, `borg/key/*`, `borg-ui/ssh-key`) | `ssh-keygen`, partie publique remplacée en face (GitHub, serveurs, storage2) |
| `borg/passphrase` | `borg key change-passphrase` ; les archives passées ne sont pas rechiffrées |
| `tokens/*`, `mail/password` | le fournisseur |
| `newt/*`, `pangolin/secret`, `crowdsec/*` | dashboard pangolin, `cscli` |
| Fichiers d'env des services (`immich`, `papra`, `wow-cp`) | chaque application : mot de passe de base, clé d'appli |
| `ntfy/topic`, `kuma/*` | un nouveau topic, un nouveau moniteur push |

## 4. Déployer et vérifier

Commiter, puis `just install` et chaque `just install_<machine>`. Redémarrer
les conteneurs : aucun secret n'a de `restartUnits`.

```bash
# L'ancienne clé doit être refusée
SOPS_AGE_KEY_FILE=/tmp/old-key.txt sops -d secrets/skitarii.yaml > /dev/null
```

Puis les deux boucles de [Vérifier](/nixos/fr/operations/secrets-backup/#vérifier).

## Testé

Le 2026-11-18, l'étape 2 et le refus, avec des clés jetables sur des fichiers
factices :

- après `updatekeys`, l'ancienne clé est refusée mais le chiffré est inchangé ;
- après `rotate`, le chiffré change ;
- l'ancienne clé ouvre toujours la version précédente du fichier.

Jamais lancé : les commandes YubiKey de l'étape 1, et l'étape 3 sur les vrais
fichiers.
