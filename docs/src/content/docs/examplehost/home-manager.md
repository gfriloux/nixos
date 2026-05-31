---
title: The Sanctum — Home Manager on exampleHost
description: User environment configuration, SSH setup, shell variables, and Git signing.
---

The Sanctum is the Techpriest's personal domain — shell, SSH, mail, and rites for daily labour.

Files: `homes/x86_64-linux/kuri@exampleHost/`

## Structure

| File | Contents |
|---|---|
| `default.nix` | Primary config: packages, fish, git, sops HM |
| `ssh.nix` | SSH config: matchBlocks, sops keys, ssh-agent |
| `mail.nix` | Mail config (notmuch, alot) |

## SSH & ssh-agent

ssh-agent is activated via Home Manager (`services.ssh-agent.enable = true`).
Socket: `/run/user/1000/ssh-agent` (exported in fish via `shellInitLast`).

All SSH private keys live in sops (`secrets/kuri_exampleHost.yaml` under `ssh/keys/`). They are unsealed to `/run/user/1000/secrets/`.

## Fish — The Shell Rite

Environment variables are loaded from the secret `workspace` file at each shell invocation:

```fish
envsource /run/user/1000/secrets/workspace
```

Alias: `rbw` → `rbw-wrapper` (injects email and server URL from sops).

## Git

Default GPG signature with key `52381C92A5071464F3160D257D4216D8BDDA9A09`.

## Deployment

Home Manager is anointed via `just install` (`nh os switch .`), which also activates the Home Manager configuration.
