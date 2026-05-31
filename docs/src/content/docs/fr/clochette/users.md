---
title: Utilisateurs & Homes
description: Profils utilisateurs — guillaume (admin), weechat (IRC persistante).
---

Deux utilisateurs gèrent le sanctuaire clochette : l'administrateur et le gardien de la session IRC.

## guillaume

Utilisateur admin principal.

| Paramètre | Valeur |
|---|---|
| Shell | fish |
| Groupes | `wheel`, `docker` |
| Mot de passe | sops (`users/guillaume/hashed-password`, `neededForUsers = true`) |
| SSH | clé ed25519 + clé sk-ssh-ed25519 (YubiKey) |
| Home Manager | `homes/x86_64-linux/guillaume@clochette/` |

## weechat

Utilisateur dédié à la session IRC persistante.

| Paramètre | Valeur |
|---|---|
| Shell | fish |
| Groupes | — |
| SSH | clé ed25519 + clé sk-ssh-ed25519 (YubiKey weechat) |
| Home Manager | `homes/x86_64-linux/weechat@clochette/` |

Le shell et SSH sont intentionnels : l'utilisateur `weechat` est utilisé
pour attacher à une session zellij/weechat persistante.

```bash
# Se connecter à la session IRC
ssh irc.friloux.me
zellij attach
```

## Politique

`users.mutableUsers = false` — NixOS gère entièrement `/etc/shadow`.
Toute modification de mot de passe passe par sops + redéploiement.

Les clés SSH autorisées sont déclarées directement dans `users.nix`
(hardcodées, pas via sops) car elles ne sont pas secrètes.
