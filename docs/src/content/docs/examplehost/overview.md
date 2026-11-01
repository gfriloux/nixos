---
title: "exampleHost"
description: Desktop workstation. NixOS, Plasma 6, ZFS mirror, AMD GPU.
sidebar:
  order: 1
  label: "Overview"
---

| | |
|---|---|
| User | `kuri`, fish, groups `users` `networkmanager` `video` `audio` `docker` `wheel` `dialout` |
| STC relics | `zfs`, `plasma6` (fr layout, sddm `catppuccin-mocha-mauve`), `amdGpu` (initrd) |
| STC profiles | `cogitator.workstation` (Plasma, hardening, YubiKey; filesystem hardening off for KDE polkit and Steam/Proton), `cogitator.gaming` |
| Services | Docker (ZFS storage driver), zrepl (pulls snapshots from storage2), Tailscale, flatpak |
| sops | age key `/etc/sops/age/keys.txt`, opens `kuri_exampleHost.yaml` only |
| Home Manager | `homes/x86_64-linux/kuri@exampleHost/`, see [Home Manager](/nixos/examplehost/home-manager/) |

Pages: [ZFS](/nixos/examplehost/zfs/), [AMD GPU](/nixos/examplehost/amd-gpu/), [Plasma 6](/nixos/examplehost/plasma6/).

## Home Manager secrets

sops-nix writes them to `/run/user/1000/secrets/`.

| Secret | Use |
|---|---|
| `rbw/server` | Bitwarden (rbw) server URL |
| `workspace` | shell environment variables |
| `mail/address`, `mail/password`, `mail/tags/*` | mail account and tagging rules |
| `ssh/keys/guillaume@clochette`, `ssh/keys/weechat@clochette` | clochette |
| `ssh/keys/guillaume@skitarii` | skitarii |
| `ssh/keys/root@rogueleader` | RogueLeader |
| `ssh/keys/kuri@storage2` | storage2 |
| `ssh/keys/github` | GitHub |
