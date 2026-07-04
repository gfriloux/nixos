---
title: The Catechism
description: Operational doctrine of the KURI Forge — a personal NixOS flake governing three machine-shrines and the reliquaries that guard their secrets.
---

This Codex chronicles the KURI Forge: the sacred configuration that consecrates three machine-shrines and the reliquaries that guard their secrets. A tired Techpriest at 2am will find the reinstallation rites in **Rites Opérationnels**; those seeking understanding begin with **Sacred Geometry**.

## The Three Machine-Shrines

| Shrine | Role | OS |
|---|---|---|
| **exampleHost** | Primary workstation-shrine | NixOS, ZFS, AMD GPU, Plasma 6 |
| **clochette** | VPS: exposed services | NixOS, Docker, Traefik |
| **RogueLeader** | Dedicated home-shrine | NixOS, Docker |

## The Forge — Repository Structure

The complete consecration is versioned in a snowfall-lib NixOS flake.

```text
systems/x86_64-linux/
├── exampleHost/   # The workstation-shrine's configuration
├── clochette/     # The VPS-shrine's configuration
└── RogueLeader/   # The home-shrine's configuration

homes/x86_64-linux/
├── kuri@exampleHost/     # Workstation Sanctum
├── guillaume@clochette/  # VPS admin Sanctum
└── weechat@clochette/    # IRC daemon-attendant Sanctum

modules/nixos/
├── docker-traefik/       # The Gatekeeper
├── docker-crowdsec/      # The Sentinel
└── notify-docker/        # The Astropath

secrets/
├── clochette.yaml         # VPS reliquaries (age-sealed)
├── kuri_exampleHost.yaml  # Workstation reliquaries (age-sealed)
└── RogueLeader.yaml       # Home reliquaries (age-sealed)
```

## How to Navigate This Codex

- **Emergency rites**: Go directly to **Rites Opérationnels**
- **Understanding the Forge**: Start with **Sacred Geometry**
- **Tending bound daemons**: Consult the section for your shrine
