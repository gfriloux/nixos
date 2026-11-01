---
title: "Architecture"
description: Flake layout, inputs, deployment and rules shared by the four machines.
sidebar:
  order: 1
  label: "Overview"
---

[snowfall-lib](https://github.com/snowfallorg/lib) flake, four machines.

```text
systems/x86_64-linux/<machine>/        # one NixOS config per machine
homes/x86_64-linux/<user>@<machine>/   # one Home Manager config per user
modules/home/dank-shell/               # only local module (desktop bar)
secrets/                               # sops, one file per machine
```

snowfall-lib does not inject modules: each machine imports the ones it uses.

## Inputs

| Input | Provides |
|---|---|
| `stc` | Relics `stc.relics.*` (docker, crowdsec, notify, SSH, Nix upkeep), helpers `stc.lib.docker.*`, purity seals |
| `sops-nix` | age-encrypted secrets |
| `disko` | Declarative partitioning |
| `home-manager` | User environments |
| `dms` | DankMaterialShell desktop bar |
| `pgpilot`, `noosphere`, `astropath` | Personal tools |

## Deploy

| Machine | Command | Access |
|---|---|---|
| exampleHost | `just install` | local (`nh os switch`) |
| clochette | `just install_clochette` | Tailscale |
| skitarii | `just install_skitarii` | Tailscale |
| RogueLeader | `just install_rogueleader` | LAN, `rogueleader.home` |

Details: [Deployment](/nixos/operations/deployment/).

## Rules

- `users.mutableUsers = false` everywhere: NixOS owns `/etc/shadow`.
- A secret is declared next to the service that reads it (`docker-*.nix`). Keys and files: [Secrets](/nixos/architecture/secrets/).
- Static config files: `systemd.tmpfiles.rules` with `L+` (link to the store), never `C`.
- Single-machine config: direct NixOS options, no `mkOption`/`cfg.*`.
- Public web: only through skitarii's [gateway](/nixos/skitarii/gateway/). Containers: [Docker patterns](/nixos/architecture/docker/).
