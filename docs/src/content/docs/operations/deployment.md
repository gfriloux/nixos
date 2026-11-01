---
title: "Deployment"
description: just recipes to build, deploy, roll back, update.
---

From the repository root, on exampleHost.

| Machine | Build only | Deploy | Access |
|---|---|---|---|
| exampleHost | `just build` | `just install` (`nh os switch`, Home Manager included) | local |
| clochette | `just build_clochette` | `just install_clochette` | Tailscale |
| skitarii | `just build_skitarii` | `just install_skitarii` | Tailscale |
| RogueLeader | `just build_rogueleader` | `just install_rogueleader`, `just home_rogueleader` (HM only) | LAN |

Remote deploys use `nixos-rebuild --target-host guillaume@<host>` and ask for the
sudo password (`--ask-sudo-password` is already in the recipe).

## Before

```bash
just test          # pre-commit: statix, deadnix, alejandra
nix flake check    # STC purity seals: nix, gitleaks, markdown
```

## Roll back

```bash
nixos-rebuild list-generations
sudo nixos-rebuild switch --rollback   # on the target machine
```

Or pick an earlier generation in GRUB at reboot.

## Other recipes

| Recipe | Effect |
|---|---|
| `just update` | `nix flake update` (build every machine afterwards) |
| `just secrets`, `just secrets_<machine>` | `sops` on the machine's file, see [Secrets](/nixos/architecture/secrets/) |
| `just scan` | Trivy (HIGH, CRITICAL) on clochette's Docker images |
