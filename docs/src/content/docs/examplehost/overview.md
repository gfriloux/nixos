---
title: exampleHost — The Workstation-Shrine
description: Primary machine-shrine running Plasma 6 on NixOS with ZFS mirror storage.
---

Behold exampleHost — the Techpriest's primary workstation, where the machine-spirit tends both labour and leisure. A ZFS-mirrored sanctuary running NixOS with Plasma 6 at its core.

## The Pilgrim's Account

| Parameter | Value |
|---|---|
| User | `kuri` |
| Shell | fish |
| Groups | `users`, `networkmanager`, `video`, `audio`, `docker`, `wheel` |
| Home Manager | `homes/x86_64-linux/kuri@exampleHost/` |

## Bound Daemons & Services

| Service | Role |
|---|---|
| sddm | Display manager (Wayland) |
| Plasma 6 | Sacred desktop environment |
| pipewire | Audio (ALSA + PulseAudio compat) |
| Docker | Local bound daemons (ZFS storage driver) |
| zrepl | Pulls ZFS snapshots from storage2 |
| Tailscale | Mesh VPN |
| pcscd | Smart card daemon (YubiKey) |
| flatpak | Sandboxed applications |

## The Sealed Sanctum — Home Manager Secrets

Home Manager's reliquaries are deposited in `/run/user/1000/secrets/` by sops-nix:

| Secret | Path | Usage |
|---|---|---|
| `rbw/server` | `rbw_server` | Bitwarden (rbw) server URL |
| `workspace` | `workspace` | Shell environment variables |
| `ssh/keys/guillaume@clochette` | — | SSH key: clochette admin |
| `ssh/keys/weechat@clochette` | — | SSH key: weechat daemon |
| `ssh/keys/kuri@storage2` | — | SSH key: storage2 archive |
| `ssh/keys/root@rogueleader` | — | SSH key: RogueLeader |
| `ssh/keys/github` | — | SSH key: GitHub |
| `mail/address` | — | Mail address (rbw-wrapper) |

## Notable Applications

Steam, Heroic, WineWow64 (gaming), Transmission, GIMP, Ghostty, rustup,
yubikey-manager, rbw (Bitwarden CLI), git-workspace, claude-code.
