# Introduction

Documentation opérationnelle de l'infrastructure NixOS personnelle.

## Machines

| Machine | Rôle | OS |
|---|---|---|
| **exampleHost** | Poste de travail principal | NixOS, ZFS, AMD GPU, Plasma 6 |
| **clochette** | Serveur VPS (Scaleway) | NixOS, Docker, Traefik |
| **RogueLeader** | Serveur dédié domestique | NixOS, Docker |

## Dépôt

La configuration complète est versionnée dans un flake NixOS utilisant
[snowfall-lib](https://github.com/snowfallorg/lib).

Structure du dépôt :

```
systems/x86_64-linux/
├── exampleHost/   # Config système du poste de travail
├── clochette/     # Config système du VPS
└── RogueLeader/   # Config système du serveur dédié

homes/x86_64-linux/
├── kuri@exampleHost/     # Home Manager du poste de travail
├── guillaume@clochette/  # Home Manager du VPS
└── weechat@clochette/    # Session IRC persistante

modules/nixos/
├── docker-traefik/       # Reverse proxy Traefik
├── docker-crowdsec/      # WAF CrowdSec
└── notify-docker/        # Surveillance et notifications Docker

secrets/
├── clochette.yaml         # Secrets VPS (chiffrés age)
├── kuri_exampleHost.yaml  # Secrets poste de travail (chiffrés age)
└── RogueLeader.yaml       # Secrets serveur dédié (chiffrés age)
```

## Comment utiliser cette documentation

- **Réinstallation d'urgence** : aller directement à la section **Opérations**
- **Comprendre l'infrastructure** : commencer par **Architecture**
- **Ajouter ou modifier un service** : consulter la section de la machine concernée
