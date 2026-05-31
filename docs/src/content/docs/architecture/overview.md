---
title: Sacred Geometry — Architecture Overview
description: Structure of the KURI Forge — snowfall-lib, deployment patterns, secrets, and services.
---

The Forge is structured as a snowfall-lib NixOS flake, its three machine-shrines declared beneath `systems/x86_64-linux/` and its bound daemons managed through composable sacred patterns.

## Sacred Geometry — Flake Structure

The repository uses [snowfall-lib](https://github.com/snowfallorg/lib) to orchestrate the Forge. Each machine-shrine is a system declared under `systems/x86_64-linux/<name>/`; each Sanctum (user environment) under `homes/x86_64-linux/<user>@<machine>/`.

Reusable sacred patterns live in `modules/nixos/` and are exposed via `lib.kuri`.

:::note[Marginalia]
snowfall-lib does **not** propagate modules globally — each shrine must explicitly import the patterns it requires.
:::

## The Rites of Anointment

- **exampleHost**: `nh os switch .` (local sanctification)
- **clochette**: `nixos-rebuild switch --target-host ...` (via Tailscale SSH)
- **RogueLeader**: `nixos-rebuild switch --target-host ...` (via local network)

## The Reliquary

All secrets are sealed with age + sops-nix. The private age key of exampleHost is the master key — it can unseal all reliquaries across the Forge.

## Bound Daemons — Services Web (clochette)

All web services run as bound daemons (Docker containers) behind the Gatekeeper (Traefik).
Traefik manages Let's Encrypt certificates (TLS challenge).
The Sentinel (CrowdSec) guards all exposed routes.

## The Astropath

The `notify-docker` pattern watches all containers bearing the label `friloux.me/health-watch = "true"` and heralds their omens via ntfy.sh if they fall into `unhealthy` state or enter failure.

## Principles of Consecration

- `users.mutableUsers = false` across all shrines — NixOS owns `/etc/shadow`
- Secrets are declared near the service that uses them (within `docker-*.nix` files)
- Static config files use `systemd.tmpfiles.rules` with `L+` (symlink to the Nix store)
- Single-machine configurations avoid `mkOption`/`cfg.*` abstraction — use direct NixOS options
