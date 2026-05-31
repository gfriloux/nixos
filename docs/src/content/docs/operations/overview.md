---
title: Rites Opérationnels — Deployment & Maintenance
description: Common operations, emergency recovery, and diagnostic procedures for the KURI Forge.
---

This section gathers all operational ceremonies — from daily maintenance to emergency rites and recovery from calamity.

## Common Rites

| Task | Page |
|---|---|
| Deploy a configuration | [Rites of Anointment](deployment.md) |
| Edit a sops secret | [The Reliquary & sops-nix](sops.md) |
| Monitor services | [The Astropath & Observability](monitoring.md) |
| Diagnose failure | [Dépannage](troubleshooting.md) |

## Recovery Rites

| Task | Page |
|---|---|
| Backup/restore age keys | [Reliquary Backup & Restoration](secrets-backup.md) |
| Reinstall exampleHost | [Rite of Resurrection: exampleHost](reinstall-examplehost.md) |
| Reinstall clochette | [Rite of Resurrection: clochette](reinstall-clochette.md) |
| Re-enroll Tailscale | [Tailscale — Re-enrollment](tailscale.md) |

## General Principle

Every change to the flake follows this cycle:

1. Modify `.nix` files
2. `just test` (linters via pre-commit)
3. `just build` or `just build_clochette` (build without deploying)
4. `just install` or `just install_clochette` (deploy)
5. Validate expected behaviour
6. Commit + push
