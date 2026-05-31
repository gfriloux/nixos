# exampleHost — poste de travail

Poste de travail principal. Bureau KDE Plasma 6 sur NixOS avec ZFS en miroir.

## Profil utilisateur

| Paramètre | Valeur |
|---|---|
| Utilisateur | `kuri` |
| Shell | fish |
| Groupes | `users`, `networkmanager`, `video`, `audio`, `docker`, `wheel` |
| Home Manager | `homes/x86_64-linux/kuri@exampleHost/` |

## Services actifs

| Service | Rôle |
|---|---|
| sddm | Display manager (Wayland) |
| Plasma 6 | Environnement de bureau |
| pipewire | Audio (ALSA + PulseAudio compat) |
| Docker | Containers locaux (storage driver ZFS) |
| zrepl | Pull de snapshots ZFS depuis storage2 |
| Tailscale | VPN mesh |
| pcscd | Daemon carte à puce (YubiKey) |
| flatpak | Applications sandboxées |

## Secrets Home Manager

Les secrets HM sont déposés dans `/run/user/1000/secrets/` par sops-nix :

| Secret | Chemin | Usage |
|---|---|---|
| `rbw/server` | `rbw_server` | URL serveur Bitwarden (rbw) |
| `workspace` | `workspace` | Variables d'environnement shell |
| `ssh/keys/guillaume@clochette` | — | Clé SSH pour clochette |
| `ssh/keys/weechat@clochette` | — | Clé SSH weechat |
| `ssh/keys/kuri@storage2` | — | Clé SSH storage2 |
| `ssh/keys/root@rogueleader` | — | Clé SSH RogueLeader |
| `ssh/keys/github` | — | Clé SSH GitHub |
| `mail/address` | — | Adresse mail (rbw-wrapper) |

## Logiciels notables

Steam, Heroic, WineWow64 (jeux), Transmission, GIMP, Ghostty, rustup,
yubikey-manager, rbw (Bitwarden CLI), git-workspace, claude-code.
