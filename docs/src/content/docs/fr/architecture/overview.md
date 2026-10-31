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

Tous les secrets sont scellés avec age + sops-nix. La clé de chaque machine n'ouvre que son propre reliquaire ; l'édition passe par des clés d'administration qui ne sont sur aucune machine (une YubiKey et une clé de secours hors ligne). Voir [Reliquaires de Secrets](secrets.md).

## Démons Liés — Services Web (clochette, RogueLeader)

Tous les services web fonctionnent comme des démons liés (containers Docker)
publiés par la passerelle pangolin de skitarii. Chaque machine fait tourner un
container `newt` qui porte le trafic par un tunnel sortant : aucune des deux ne
fait tourner traefik ou crowdsec, ni n'ouvre de port web. Le traefik de skitarii
gère les certificats Let's Encrypt et son CrowdSec garde toutes les routes. Voir
[La Porte](../skitarii/gateway.md).

## L'Astropathe

Le motif `notify-docker` observe tous les containers portant le label `friloux.me/health-watch = "true"` et annonce leurs présages via ntfy.sh s'ils tombent en état `unhealthy` ou entrent en défaillance.

## Principes de Consécration

- `users.mutableUsers = false` sur tous les sanctuaires — NixOS possède `/etc/shadow`
- Les secrets sont déclarés près du service qui les utilise (dans les fichiers `docker-*.nix`)
- Les fichiers de config statiques utilisent `systemd.tmpfiles.rules` avec `L+` (symlink vers le Nix store)
- Les configurations mono-machine évitent l'abstraction `mkOption`/`cfg.*` — utilisent des options NixOS directes
