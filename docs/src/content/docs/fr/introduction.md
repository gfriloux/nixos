---
title: La Catéchèse
description: Doctrine opérationnelle de la Forge KURI — un flake NixOS personnel régissant trois sanctuaires-machines.
---

Ce Codex consigne la Forge KURI : la configuration sacrée qui consacre trois sanctuaires-machines et les reliquaires qui en gardent les secrets. Le Techprêtre épuisé à 2h du matin trouvera les rites de réinstallation dans les **Rites Opérationnels** ; ceux qui cherchent à comprendre commencent par la **Géométrie Sacrée**.

## Les Trois Sanctuaires-Machines

| Machine | Rôle | OS |
|---|---|---|
| **exampleHost** | Sanctuaire de travail principal | NixOS, ZFS, AMD GPU, Plasma 6 |
| **clochette** | Serveur VPS (Scaleway) | NixOS, Docker, Traefik |
| **RogueLeader** | Serveur dédié domestique | NixOS, Docker |

## Le Dépôt

La configuration complète est versionnée dans un flake NixOS utilisant [snowfall-lib](https://github.com/snowfallorg/lib).

Structure de la Forge :

```text
systems/x86_64-linux/
├── exampleHost/   # Config système du sanctuaire de travail
├── clochette/     # Config système du VPS
└── RogueLeader/   # Config système du serveur dédié

homes/x86_64-linux/
├── kuri@exampleHost/     # Home Manager du sanctuaire de travail
├── guillaume@clochette/  # Home Manager du VPS
└── weechat@clochette/    # Session IRC persistante

modules/nixos/
├── docker-traefik/       # Reverse proxy Traefik (le Gardien)
├── docker-crowdsec/      # WAF CrowdSec (la Sentinelle)
└── notify-docker/        # Surveillance et notifications Docker (l'Astropathe)

secrets/
├── clochette.yaml         # Reliquaires VPS (chiffrés age)
├── kuri_exampleHost.yaml  # Reliquaires du sanctuaire de travail (chiffrés age)
└── RogueLeader.yaml       # Reliquaires du serveur dédié (chiffrés age)
```

## Comment naviguer ce Codex

- **Réinstallation d'urgence** : allez directement aux **Rites Opérationnels**
- **Comprendre l'infrastructure** : commencez par la **Géométrie Sacrée**
- **Ajouter ou modifier un service** : consultez la section du sanctuaire-machine concerné
