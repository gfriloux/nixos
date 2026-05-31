---
title: Rites of Anointment — Deployment Commands
description: Building and deploying NixOS configurations to exampleHost, clochette, and RogueLeader.
---

Reference of the rites used to forge and anoint NixOS configurations.
All `just` commands execute from the repository root.

## exampleHost — Local Sanctification

```bash
# Test the configuration without applying it
just build

# Apply the configuration (equivalent to nixos-rebuild switch)
just install
```

`just install` executes `nh os switch .`, which applies the system configuration
and activates Home Manager for the current user.

## clochette — Remote VPS Anointment via Tailscale

```bash
# Build only
just build_clochette

# Deploy
just install_clochette --ask-sudo-password
```

The underlying full command:

```bash
nixos-rebuild switch \
  --flake .#clochette \
  --target-host guillaume@clochette.friloux.me \
  --sudo \
  --ask-sudo-password
```

**Prerequisites**: Tailscale active on both machines, `clochette.friloux.me`
resolves to the Tailscale IP, and SSH is functional.

## RogueLeader — Home-Shrine Anointment via Local Network

```bash
# Build only
just build_rogueleader

# Deploy the system
just install_rogueleader --ask-sudo-password

# Deploy Home Manager only
just home_rogueleader
```

## Pre-deployment Verification

```bash
# Run all linters (statix, deadnix, alejandra) via pre-commit
just test

# Evaluate the flake without building
nix flake check
```

## Rollback

If a deployment produces an unstable system:

```bash
# List NixOS generations
nixos-rebuild list-generations

# Revert to previous generation
nixos-rebuild switch --rollback

# Or select a specific generation at boot (via GRUB)
```

For clochette via SSH:

```bash
ssh guillaume@clochette.friloux.me \
  "sudo nixos-rebuild switch --rollback"
```

## Editing Secrets

```bash
# exampleHost secrets
just secrets

# clochette secrets
just secrets_clochette

# RogueLeader secrets
just secrets_rogueleader
```

These commands open the encrypted file in `$EDITOR` via `sops`.
Save and quit automatically re-encrypts.

## Docker Image Security Scan

```bash
just scan
```

Runs Trivy on all Docker images in the clochette configuration
and displays HIGH and CRITICAL vulnerabilities.

## Update Flake Dependencies

```bash
just update
```

Updates `flake.lock` with the latest revisions of all inputs.
Follow with `just build_clochette` to verify nothing breaks.
