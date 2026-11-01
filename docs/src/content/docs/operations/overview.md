---
title: "Operations"
description: Procedures, day to day and when something breaks.
sidebar:
  order: 1
  label: "Overview"
---

## Change the config

```bash
just test                 # linters (pre-commit)
just build_<machine>      # build without deploying (just build for exampleHost)
just install_<machine>    # deploy (just install for exampleHost)
```

Keep a root shell open before touching sudo or users. Details: [Deployment](/nixos/operations/deployment/).

## Day to day

| Task | Page |
|---|---|
| Edit a secret | [sops-nix](/nixos/operations/sops/) |
| Monitor | [Monitoring](/nixos/operations/monitoring/), [Failure notifications](/nixos/operations/notifications/) |
| Diagnose | [Troubleshooting](/nixos/operations/troubleshooting/) |

## When something breaks

| Task | Page |
|---|---|
| Restore data | [Restore from Borg](/nixos/operations/restore/) |
| Recover the age keys | [Age key backup](/nixos/operations/secrets-backup/) |
| Reinstall | [exampleHost](/nixos/operations/reinstall-examplehost/), [clochette](/nixos/operations/reinstall-clochette/), [skitarii](/nixos/operations/reinstall-skitarii/), [RogueLeader](/nixos/operations/reinstall-rogueleader/) |
| Re-enroll Tailscale | [Tailscale re-enrollment](/nixos/operations/tailscale/) |
