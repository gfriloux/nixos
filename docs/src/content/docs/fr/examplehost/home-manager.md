---
title: Home Manager
description: Configuration de l'environnement utilisateur kuri — SSH, Fish, Git, Secrets.
---

Configuration de l'environnement utilisateur `kuri` sur exampleHost.

Fichiers : `homes/x86_64-linux/kuri@exampleHost/`

## Structure

| Fichier | Contenu |
|---|---|
| `default.nix` | Config principale : paquets, fish, git, sops HM |
| `ssh.nix` | Config SSH : matchBlocks, clés sops, ssh-agent |
| `mail.nix` | Config mail (notmuch, alot) |

## SSH

ssh-agent activé via Home Manager (`services.ssh-agent.enable = true`).
Socket : `/run/user/1000/ssh-agent` (exporté dans fish via `shellInitLast`).

Toutes les clés SSH privées sont dans sops (`secrets/kuri_exampleHost.yaml`
sous `ssh/keys/`). Elles sont déchiffrées vers `/run/user/1000/secrets/`.

## Fish

Variables d'environnement chargées depuis le fichier secret `workspace`
au démarrage de chaque shell :

```fish
envsource /run/user/1000/secrets/workspace
```

Alias : `rbw` → `rbw-wrapper` (injecte l'email et l'URL serveur depuis sops).

## Git

Signature GPG par défaut avec la clé `52381C92A5071464F3160D257D4216D8BDDA9A09`.

## Déploiement

Home Manager est déployé via `just install` (`nh os switch .`)
qui active aussi la configuration Home Manager.
