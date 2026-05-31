---
title: Pilgrims & Sanctums — System Users & Home Manager
description: User accounts (guillaume, weechat), SSH keys, and Home Manager configuration.
---

The VPS-shrine is tended by two pilgrims: the admin and the IRC daemon-attendant.

## guillaume — The Admin

Primary administrative user.

| Parameter | Value |
|---|---|
| Shell | fish |
| Groups | `wheel`, `docker` |
| Password | sops (`users/guillaume/hashed-password`, `neededForUsers = true`) |
| SSH | ed25519 key + sk-ssh-ed25519 key (YubiKey) |
| Home Manager | `homes/x86_64-linux/guillaume@clochette/` |

## weechat — The IRC Daemon-Attendant

User dedicated to a persistent IRC session.

| Parameter | Value |
|---|---|
| Shell | fish |
| Groups | — |
| SSH | ed25519 key + sk-ssh-ed25519 key (YubiKey weechat) |
| Home Manager | `homes/x86_64-linux/weechat@clochette/` |

Shell and SSH are intentional: the `weechat` user attaches to a persistent zellij/weechat IRC session.

```bash
# Connect to the IRC session
ssh irc.friloux.me
zellij attach
```

## Policy

`users.mutableUsers = false` — NixOS fully owns `/etc/shadow`.
Any password change passes through sops + redeployment.

Authorized SSH keys are declared directly in `users.nix`
(hardcoded, not via sops) because they are not secret.
