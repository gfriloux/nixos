# nixos

Personal NixOS flake driving three machines: a workstation, a public VPS and a
home server. Built with [snowfall-lib](https://github.com/snowfallorg/lib),
secrets sealed with [sops-nix](https://github.com/Mic92/sops-nix), disks
declared with [disko](https://github.com/nix-community/disko).

[![Docs](https://img.shields.io/badge/docs-gfriloux.github.io%2Fnixos-blue)](https://gfriloux.github.io/nixos/)
[![nixpkgs](https://img.shields.io/badge/nixpkgs-unstable-brightgreen)](https://github.com/NixOS/nixpkgs/tree/nixos-unstable)
[![License](https://img.shields.io/badge/license-Apache--2.0-lightgrey)](LICENSE)

This is a working configuration, not a framework. The reusable parts — desktop
profiles, hardening, Docker relics — live in a separate flake,
[gfriloux/stc](https://github.com/gfriloux/stc); what stays here is the
host-specific layer that wires them together.

## Machines

| Host | Role | Notable |
|---|---|---|
| `exampleHost` | Workstation | ZFS mirror, AMD GPU, Plasma 6, gaming profile, YubiKey |
| `clochette` | Scaleway VPS, public services | Docker behind Traefik + CrowdSec, SSH over Tailscale only |
| `RogueLeader` | Home server | Docker behind Traefik + CrowdSec, Borg backups |

Four Home Manager configurations: `kuri@exampleHost`, `guillaume@clochette`,
`guillaume@RogueLeader`, `weechat@clochette` (a persistent zellij + WeeChat IRC
session).

## Services

Every container sits behind Traefik with Let's Encrypt certificates, and is
watched by a health poller that kills unhealthy containers so systemd restarts
them and pushes a notification to ntfy.sh.

| Service | Host | Domain |
|---|---|---|
| [Immich](https://immich.app/) — photo gallery | `clochette` | `photos.friloux.me` |
| CrowdSec Manager — WAF UI | `clochette` | internal |
| [BookStack](https://www.bookstackapp.com/) — wiki | `RogueLeader` | `wow-cp.friloux.me` |
| [Uptime Kuma](https://github.com/louislam/uptime-kuma) — monitoring | `RogueLeader` | `status.friloux.me` |
| [Papra](https://papra.app/) — document archive | `RogueLeader` | `docs.friloux.me` |
| [Mealie](https://mealie.io/) — recipes | `RogueLeader` | `cuisine.home.friloux.me` |
| Borg UI — backup browser | `RogueLeader` | `borg-ui.friloux.me` |

Image tags are pinned and bumped by Renovate, which reads the `# renovate`
comment next to each `image =` line. `just scan` runs Trivy against every image
a host declares.

## Layout

```text
systems/x86_64-linux/{exampleHost,clochette,RogueLeader}/
    default.nix              # host entry point, stc profiles, sops declarations
    disko.nix                # disk layout
    docker-*.nix             # one file per service, secrets declared alongside
    backup.nix               # Borg
homes/x86_64-linux/<user>@<host>/
secrets/                     # age-encrypted, see .sops.yaml
checks/{nix,gitleaks,markdown}/
docs/                        # Astro + Starlight, EN/FR
```

## Usage

```bash
just build                    # build exampleHost
just install                  # switch exampleHost (nh os switch)

just build_clochette
just install_clochette        # nixos-rebuild --target-host guillaume@clochette

just build_rogueleader
just install_rogueleader
just home_rogueleader         # Home Manager only

just secrets                  # edit exampleHost secrets
just secrets_clochette
just secrets_rogueleader

just test                     # pre-commit run --all-files
just update                   # nix flake update
```

Deployment goes over SSH as `guillaume`, using `--ask-sudo-password`.
`clochette` is only reachable through Tailscale.

## Secrets

Three age-encrypted files, one per host. The workstation key is the master — it
can decrypt all three, so it is the one that matters for backup and restore.

| File | Recipients |
|---|---|
| `secrets/kuri_exampleHost.yaml` | workstation |
| `secrets/clochette.yaml` | clochette + workstation |
| `secrets/RogueLeader.yaml` | RogueLeader + workstation |

The workstation reads its key from `/etc/sops/age/keys.txt`; the two servers
derive theirs from their SSH host key. Reinstalling a server changes that host
key, which means updating `.sops.yaml` and re-running `sops updatekeys`. The
[docs](https://gfriloux.github.io/nixos/) walk through the whole procedure.

## Checks

`nix flake check` runs stc's purity seals:

- `nix` — deadnix, statix, alejandra
- `gitleaks` — secret scan, allowlist in `.gitleaks.toml`
- `markdown` — rumdl

A pre-commit hook runs the Nix linters as a faster local gate.

## Documentation

Reinstallation procedures for all three machines, secrets backup and restore,
Tailscale re-enrollment, per-service guides and troubleshooting:
**<https://gfriloux.github.io/nixos/>** (also in
[French](https://gfriloux.github.io/nixos/fr/)).

```bash
just docs-dev      # localhost:4321/nixos/
just docs-build
```

## License

[Apache-2.0](LICENSE)
