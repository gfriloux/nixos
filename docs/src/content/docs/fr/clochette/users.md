---
title: "Utilisateurs"
description: "Comptes de clochette : guillaume (admin), weechat (IRC persistant)."
---

| | `guillaume` | `weechat` |
|---|---|---|
| Rôle | admin | session IRC persistante (zellij + weechat) |
| Shell | fish | fish (voulu) |
| Groupes | `wheel`, `docker` | aucun |
| Mot de passe | sops `users/guillaume/hashed-password` (`neededForUsers = true`) | aucun |
| SSH | ed25519 + sk-ssh-ed25519 (YubiKey) | ed25519 + sk-ssh-ed25519 (YubiKey weechat) |
| Home Manager | `homes/x86_64-linux/guillaume@clochette/` | `homes/x86_64-linux/weechat@clochette/` |

```bash
ssh irc.friloux.me   # en tant que weechat
zellij attach
```

- `users.mutableUsers = false` : un changement de mot de passe passe par sops + redéploiement.
- Les clés SSH autorisées sont dans `users.nix`, pas dans sops (elles ne sont pas secrètes).
