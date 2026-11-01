---
title: "Architecture"
description: Structure du flake, inputs, déploiement et principes communs aux quatre machines.
sidebar:
  order: 1
  label: "Vue d’ensemble"
---

Flake [snowfall-lib](https://github.com/snowfallorg/lib), quatre machines.

```text
systems/x86_64-linux/<machine>/        # une config NixOS par machine
homes/x86_64-linux/<user>@<machine>/   # une config Home Manager par utilisateur
modules/home/dank-shell/               # seul module local (barre de bureau)
secrets/                               # sops, un fichier par machine
```

snowfall-lib n'injecte pas les modules : chaque machine importe ceux qu'elle utilise.

## Inputs

| Input | Apporte |
|---|---|
| `stc` | Relics `stc.relics.*` (docker, crowdsec, notify, SSH, entretien Nix), helpers `stc.lib.docker.*`, purity seals |
| `sops-nix` | Secrets chiffrés age |
| `disko` | Partitionnement déclaratif |
| `home-manager` | Environnements utilisateur |
| `dms` | Barre de bureau DankMaterialShell |
| `pgpilot`, `noosphere`, `astropath` | Outils perso |

## Déployer

| Machine | Commande | Accès |
|---|---|---|
| exampleHost | `just install` | local (`nh os switch`) |
| clochette | `just install_clochette` | Tailscale |
| skitarii | `just install_skitarii` | Tailscale |
| RogueLeader | `just install_rogueleader` | LAN, `rogueleader.home` |

Détail : [Déploiement](/nixos/fr/operations/deployment/).

## Principes

- `users.mutableUsers = false` partout : NixOS possède `/etc/shadow`.
- Un secret se déclare à côté du service qui le lit (`docker-*.nix`). Clé et fichiers : [Secrets](/nixos/fr/architecture/secrets/).
- Fichiers de config statiques : `systemd.tmpfiles.rules` en `L+` (lien vers le store), jamais `C`.
- Config mono-machine : options NixOS directes, pas de `mkOption`/`cfg.*`.
- Web public : uniquement par la [passerelle](/nixos/fr/skitarii/gateway/) de skitarii. Conteneurs : [Motifs Docker](/nixos/fr/architecture/docker/).
