---
title: "Operations"
description: Common operations, emergency recovery, and diagnostic procedures for the KURI Forge.
sidebar:
  order: 1
  label: "Overview"
---

This section gathers all operational ceremonies — from daily maintenance to emergency rites and recovery from calamity.

## Common Rites

| Task | Page |
|---|---|
| Deploy a configuration | [Rites of Anointment](/nixos/operations/deployment/) |
| Edit a sops secret | [The Reliquary & sops-nix](/nixos/operations/sops/) |
| Monitor services | [The Astropath & Observability](/nixos/operations/monitoring/) |
| Diagnose failure | [Dépannage](/nixos/operations/troubleshooting/) |

## Recovery Rites

| Task | Page |
|---|---|
| Backup/restore age keys | [Reliquary Backup & Restoration](/nixos/operations/secrets-backup/) |
| Restore service data from Borg | [Rite of Restoration](/nixos/operations/restore/) |
| Reinstall exampleHost | [Rite of Resurrection: exampleHost](/nixos/operations/reinstall-examplehost/) |
| Reinstall clochette | [Rite of Resurrection: clochette](/nixos/operations/reinstall-clochette/) |
| Reinstall skitarii | [Rite of Resurrection: skitarii](/nixos/operations/reinstall-skitarii/) |
| Re-enroll Tailscale | [Tailscale — Re-enrollment](/nixos/operations/tailscale/) |

## General Principle

Every change to the flake follows this cycle:

1. Modify `.nix` files
2. `just test` (linters via pre-commit)
3. `just build` or `just build_clochette` (build without deploying)
4. `just install` or `just install_clochette` (deploy)
5. Validate expected behaviour
6. Commit + push
