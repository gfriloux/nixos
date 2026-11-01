---
title: "clochette"
description: Dedibox Scaleway qui héberge Immich, publié par la passerelle pangolin.
sidebar:
  order: 1
  label: "Vue d’ensemble"
---

| Conteneur | Domaine | Rôle |
|---|---|---|
| `newt` | | Tunnel sortant vers la [passerelle](/nixos/fr/skitarii/gateway/) |
| `immich-server` | `photos.friloux.me` | Galerie photo |
| `immich-postgres` | | PostgreSQL pour Immich |
| `immich-redis` | | Redis pour Immich |

## Exposition

- `photos.friloux.me` est un CNAME vers `skitarii.friloux.me`. newt porte le trafic jusqu'à `immich-server` sur le réseau `web` (créé par `docker-newt.nix`).
- Ni traefik, ni crowdsec, aucun port web public. TLS et bans se font sur skitarii.
- Pas de SSO pangolin (l'app Immich ne passerait pas). Les rafales de connexion sont bannies par le crowdsec de skitarii (`LePresidente/http-generic-401-bf`).
- SSH : Tailscale uniquement.

## Réseau

| | |
|---|---|
| IPv4 | `51.159.34.135/24` statique (`network.nix`), passerelle `51.159.34.1`, DNS `51.159.47.28`, `51.159.47.26` |
| IPv6 | SLAAC, EUI-64 `2001:bc8:6005:1c:208:a2ff:fe0c:6ca2` (AAAA de `clochette.friloux.me`) |
| Adresses temporaires | désactivées (`networking.tempAddresses`) : Scaleway ne laisse sortir que l'adresse EUI-64 (#108) |

:::caution
Scaleway bloque le 465 et le 587 en sortie : pas de mail direct. Les notifications passent par ntfy.sh en HTTPS.
:::

## Utilisateurs

`guillaume` (admin) et `weechat` (IRC persistant) : [Utilisateurs](/nixos/fr/clochette/users/).

## Données et sauvegarde

| Chemin | Contenu | Borg |
|---|---|---|
| `/srv/docker/photos.friloux.me/upload/` | photos, dump nocturne de la base dans `backups/` | oui |
| `/srv/docker/photos.friloux.me/db/` | PostgreSQL en cours d'usage | non (le dump le couvre) |
| `/home/weechat/.config/weechat` | config IRC | oui |

Quotidien vers `ssh://backup@storage2.friloux.me/~/clochette.friloux.me`. Restauration : [Immich](/nixos/fr/operations/restore/#immich-clochette).

`traefik/`, `crowdsec.clochette.friloux.me/`, `crowdsec-manager/` sous `/srv/docker/` sont des restes de l'ancienne pile : inutilisés, non sauvegardés.
