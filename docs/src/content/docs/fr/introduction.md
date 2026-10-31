---
title: La Catéchèse
description: Doctrine opérationnelle de la Forge KURI — un flake NixOS personnel régissant quatre sanctuaires-machines.
---

Ce Codex consigne la Forge KURI : la configuration sacrée qui consacre quatre sanctuaires-machines et les reliquaires qui en gardent les secrets. Le Techprêtre épuisé à 2h du matin trouvera les rites de réinstallation dans les **Rites Opérationnels** ; ceux qui cherchent à comprendre commencent par la **Géométrie Sacrée**.

## Les Quatre Sanctuaires-Machines

| Machine | Rôle | OS |
|---|---|---|
| **exampleHost** | Sanctuaire de travail principal | NixOS, ZFS, AMD GPU, Plasma 6 |
| **clochette** | Serveur VPS (Scaleway) : immich, publié par la passerelle | NixOS, Docker, newt (passerelle pangolin) |
| **RogueLeader** | Serveur dédié domestique : mealie, borg-ui, uptime-kuma, papra, BookStack, publiés par la passerelle | NixOS, Docker, newt (passerelle pangolin) |
| **skitarii** | Serveur VPS (OVH) : la passerelle pangolin, point d'entrée unique de tous les services web publics | NixOS, Docker, pangolin, gerbil, traefik, CrowdSec + AppSec |

## Le Dépôt

La configuration complète est versionnée dans un flake NixOS utilisant [snowfall-lib](https://github.com/snowfallorg/lib).

Structure de la Forge :

```text
systems/x86_64-linux/
├── exampleHost/   # Config système du sanctuaire de travail
├── clochette/     # Config système du VPS
├── RogueLeader/   # Config système du serveur dédié
└── skitarii/      # Config système de la passerelle

homes/x86_64-linux/
├── kuri@exampleHost/     # Home Manager du sanctuaire de travail
├── guillaume@clochette/  # Home Manager du VPS
├── guillaume@RogueLeader/  # Home Manager du serveur dédié
├── guillaume@skitarii/   # Home Manager de la passerelle
└── weechat@clochette/    # Session IRC persistante

modules/home/
└── dank-shell/           # Barre de bureau (Home Manager)

secrets/
├── clochette.yaml         # Reliquaires VPS (chiffrés age)
├── kuri_exampleHost.yaml  # Reliquaires du sanctuaire de travail (chiffrés age)
├── RogueLeader.yaml       # Reliquaires du serveur dédié (chiffrés age)
└── skitarii.yaml          # Reliquaires de la passerelle (chiffrés age)
```

Il n'y a aucun module NixOS local : les motifs serveur partagés (health-watch
et notifications de pannes Docker, CrowdSec, durcissement SSH, entretien Nix)
viennent de l'input de flake STC, sous forme d'options `stc.relics.*` et de
helpers `inputs.stc.lib.*`.

## Comment naviguer ce Codex

- **Réinstallation d'urgence** : allez directement aux **Rites Opérationnels**
- **Comprendre l'infrastructure** : commencez par la **Géométrie Sacrée**
- **Ajouter ou modifier un service** : consultez la section du sanctuaire-machine concerné
