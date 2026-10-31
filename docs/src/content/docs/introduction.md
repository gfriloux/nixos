---
title: The Catechism
description: Operational doctrine of the KURI Forge — a personal NixOS flake governing four machine-shrines and the reliquaries that guard their secrets.
---

This Codex chronicles the KURI Forge: the sacred configuration that consecrates four machine-shrines and the reliquaries that guard their secrets. A tired Techpriest at 2am will find the reinstallation rites in **Rites Opérationnels**; those seeking understanding begin with **Sacred Geometry**.

## The Four Machine-Shrines

| Shrine | Role | OS |
|---|---|---|
| **exampleHost** | Primary workstation-shrine | NixOS, ZFS, AMD GPU, Plasma 6 |
| **clochette** | VPS (Scaleway): immich, published through the gateway | NixOS, Docker, newt (pangolin gateway) |
| **RogueLeader** | Dedicated home-shrine: mealie, borg-ui, uptime-kuma, papra, BookStack, published through the gateway | NixOS, Docker, newt (pangolin gateway) |
| **skitarii** | VPS (OVH): the pangolin gateway, single entry point for every public web service | NixOS, Docker, pangolin, gerbil, traefik, CrowdSec + AppSec |

## The Forge — Repository Structure

The complete consecration is versioned in a snowfall-lib NixOS flake.

```text
systems/x86_64-linux/
├── exampleHost/   # The workstation-shrine's configuration
├── clochette/     # The VPS-shrine's configuration
├── RogueLeader/   # The home-shrine's configuration
└── skitarii/      # The gateway-shrine's configuration

homes/x86_64-linux/
├── kuri@exampleHost/     # Workstation Sanctum
├── guillaume@clochette/  # VPS admin Sanctum
├── guillaume@RogueLeader/  # Home-shrine admin Sanctum
├── guillaume@skitarii/   # Gateway admin Sanctum
└── weechat@clochette/    # IRC daemon-attendant Sanctum

modules/home/
└── dank-shell/           # Desktop bar (Home Manager)

secrets/
├── clochette.yaml         # VPS reliquaries (age-sealed)
├── kuri_exampleHost.yaml  # Workstation reliquaries (age-sealed)
├── RogueLeader.yaml       # Home reliquaries (age-sealed)
└── skitarii.yaml          # Gateway reliquaries (age-sealed)
```

There is no local NixOS module: shared server patterns (Docker health-watch
and failure notifications, CrowdSec, SSH hardening, Nix housekeeping) come from
the STC flake input, as `stc.relics.*` options and `inputs.stc.lib.*` helpers.

## How to Navigate This Codex

- **Emergency rites**: Go directly to **Rites Opérationnels**
- **Understanding the Forge**: Start with **Sacred Geometry**
- **Tending bound daemons**: Consult the section for your shrine
