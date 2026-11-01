---
title: "Users"
description: "clochette accounts: guillaume (admin), weechat (persistent IRC)."
---

| | `guillaume` | `weechat` |
|---|---|---|
| Role | admin | persistent IRC session (zellij + weechat) |
| Shell | fish | fish (intentional) |
| Groups | `wheel`, `docker` | none |
| Password | sops `users/guillaume/hashed-password` (`neededForUsers = true`) | none |
| SSH | ed25519 + sk-ssh-ed25519 (YubiKey) | ed25519 + sk-ssh-ed25519 (YubiKey weechat) |
| Home Manager | `homes/x86_64-linux/guillaume@clochette/` | `homes/x86_64-linux/weechat@clochette/` |

```bash
ssh irc.friloux.me   # as weechat
zellij attach
```

- `users.mutableUsers = false`: a password change goes through sops + redeploy.
- Authorized SSH keys are in `users.nix`, not in sops (they are not secret).
