---
title: Géométrie Sacrée — Vue d'ensemble de l'architecture
description: Structure de la Forge KURI — snowfall-lib, motifs de déploiement, reliquaires, et services liés.
---

La Forge est structurée comme un flake NixOS snowfall-lib, ses trois sanctuaires-machines déclarés sous `systems/x86_64-linux/` et ses démons liés gérés par des motifs sacrés composables.

## Géométrie Sacrée — Structure du Flake

Le dépôt utilise [snowfall-lib](https://github.com/snowfallorg/lib) pour orchestrer la Forge. Chaque sanctuaire-machine est un système déclaré sous `systems/x86_64-linux/<nom>/` ; chaque Sanctum (environnement utilisateur) sous `homes/x86_64-linux/<utilisateur>@<machine>/`.

Les motifs sacrés réutilisables vivent dans `modules/nixos/` et sont exposés via `lib.kuri`.

:::note[Marginalia]
snowfall-lib **ne propage pas** les modules globalement — chaque sanctuaire doit importer explicitement les motifs qu'il requiert.
:::

## Les Rites d'Onction

- **exampleHost** : `nh os switch .` (sanctification locale)
- **clochette** : `nixos-rebuild switch --target-host ...` (via SSH Tailscale)
- **RogueLeader** : `nixos-rebuild switch --target-host ...` (via réseau local)

## Le Reliquaire

Tous les secrets sont scellés avec age + sops-nix. La clé privée age de exampleHost est la clé maîtresse — elle peut sceller tous les reliquaires à travers la Forge.

## Démons Liés — Services Web (clochette)

Tous les services web fonctionnent comme des démons liés (containers Docker) derrière le Gardien (Traefik).
Traefik gère les certificats Let's Encrypt (défi TLS).
La Sentinelle (CrowdSec) garde toutes les routes exposées.

## L'Astropathe

Le motif `notify-docker` observe tous les containers portant le label `friloux.me/health-watch = "true"` et annonce leurs présages via ntfy.sh s'ils tombent en état `unhealthy` ou entrent en défaillance.

## Principes de Consécration

- `users.mutableUsers = false` sur tous les sanctuaires — NixOS possède `/etc/shadow`
- Les secrets sont déclarés près du service qui les utilise (dans les fichiers `docker-*.nix`)
- Les fichiers de config statiques utilisent `systemd.tmpfiles.rules` avec `L+` (symlink vers le Nix store)
- Les configurations mono-machine évitent l'abstraction `mkOption`/`cfg.*` — utilisent des options NixOS directes
