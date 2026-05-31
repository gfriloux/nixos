# Vue d'ensemble de l'architecture

## Flake NixOS avec snowfall-lib

Le dépôt utilise [snowfall-lib](https://github.com/snowfallorg/lib) pour structurer
le flake. Chaque machine est un système déclaré sous `systems/x86_64-linux/<nom>/`
et chaque utilisateur sous `homes/x86_64-linux/<user>@<machine>/`.

Les modules réutilisables sont dans `modules/nixos/` et exposés via `lib.kuri`.

> snowfall-lib **ne propage pas** les modules globalement : chaque système doit
> importer explicitement les modules qu'il utilise.

## Déploiement

- **exampleHost** : `nh os switch .` (local)
- **clochette** : `nixos-rebuild switch --target-host ...` (via SSH Tailscale)
- **RogueLeader** : `nixos-rebuild switch --target-host ...` (via réseau local)

## Secrets

Chiffrés avec age + sops-nix. La clé privée age de exampleHost est la clé maîtresse
qui peut déchiffrer tous les secrets de l'infrastructure.

## Services web (clochette)

Tous les services web sont des containers Docker derrière Traefik.
Traefik gère les certificats Let's Encrypt (TLS challenge).
CrowdSec protège toutes les routes exposées.

## Surveillance

Le module `notify-docker` surveille tous les containers labellés
`friloux.me/health-watch = "true"` et envoie des notifications via ntfy.sh
en cas de panne ou d'état `unhealthy`.

## Principes de configuration

- `users.mutableUsers = false` sur toutes les machines — NixOS gère `/etc/shadow`
- Les secrets sont déclarés près du service qui les utilise (dans `docker-*.nix`)
- Les fichiers de config statiques utilisent `systemd.tmpfiles.rules` avec `L+` (symlink)
- Pas d'abstraction `mkOption` pour les configs mono-machine — options NixOS directes
