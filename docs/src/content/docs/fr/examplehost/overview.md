---
title: "exampleHost"
description: Poste de travail. NixOS, Plasma 6, miroir ZFS, GPU AMD.
sidebar:
  order: 1
  label: "Vue d’ensemble"
---

| | |
|---|---|
| Utilisateur | `kuri`, fish, groupes `users` `networkmanager` `video` `audio` `docker` `wheel` `dialout` |
| Relics STC | `zfs`, `plasma6` (clavier fr, sddm `catppuccin-mocha-mauve`), `amdGpu` (initrd) |
| Profils STC | `cogitator.workstation` (Plasma, durcissement, YubiKey ; durcissement du système de fichiers coupé pour polkit KDE et Steam/Proton), `cogitator.gaming` |
| Services | Docker (pilote de stockage ZFS), zrepl (tire les snapshots depuis storage2), Tailscale, flatpak |
| sops | clé age `/etc/sops/age/keys.txt`, n'ouvre que `kuri_exampleHost.yaml` |
| Home Manager | `homes/x86_64-linux/kuri@exampleHost/`, voir [Home Manager](/nixos/fr/examplehost/home-manager/) |

Pages : [ZFS](/nixos/fr/examplehost/zfs/), [GPU AMD](/nixos/fr/examplehost/amd-gpu/), [Plasma 6](/nixos/fr/examplehost/plasma6/).

## Secrets Home Manager

sops-nix les écrit dans `/run/user/1000/secrets/`.

| Secret | Usage |
|---|---|
| `rbw/server` | URL du serveur Bitwarden (rbw) |
| `workspace` | variables d'environnement du shell |
| `mail/address`, `mail/password`, `mail/tags/*` | compte mail et règles de tags |
| `ssh/keys/guillaume@clochette`, `ssh/keys/weechat@clochette` | clochette |
| `ssh/keys/guillaume@skitarii` | skitarii |
| `ssh/keys/root@rogueleader` | RogueLeader |
| `ssh/keys/kuri@storage2` | storage2 |
| `ssh/keys/github` | GitHub |
