---
title: "Déploiement"
description: Recettes just pour construire, déployer, revenir en arrière, mettre à jour.
---

Depuis la racine du dépôt, sur exampleHost.

| Machine | Build seul | Déployer | Accès |
|---|---|---|---|
| exampleHost | `just build` | `just install` (`nh os switch`, Home Manager compris) | local |
| clochette | `just build_clochette` | `just install_clochette` | Tailscale |
| skitarii | `just build_skitarii` | `just install_skitarii` | Tailscale |
| RogueLeader | `just build_rogueleader` | `just install_rogueleader`, `just home_rogueleader` (HM seul) | LAN |

Les déploiements distants passent par `nixos-rebuild --target-host guillaume@<hôte>` et
demandent le mot de passe sudo (`--ask-sudo-password` est déjà dans la recette).

## Avant

```bash
just test          # pre-commit : statix, deadnix, alejandra
nix flake check    # purity seals STC : nix, gitleaks, markdown
```

## Revenir en arrière

```bash
nixos-rebuild list-generations
sudo nixos-rebuild switch --rollback   # sur la machine visée
```

Ou choisir une génération précédente dans GRUB au reboot.

## Autres recettes

| Recette | Effet |
|---|---|
| `just update` | `nix flake update` (builder chaque machine ensuite) |
| `just secrets`, `just secrets_<machine>` | `sops` sur le fichier de la machine, voir [Secrets](/nixos/fr/architecture/secrets/) |
| `just scan` | Trivy (HIGH, CRITICAL) sur les images Docker de clochette |
