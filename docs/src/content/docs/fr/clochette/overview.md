---
title: clochette — Serveur VPS
description: Configuration du VPS Scaleway — services Docker, exposition via la passerelle pangolin, utilisateurs.
---

VPS Scaleway hébergeant les services web personnels, publiés par la passerelle pangolin de skitarii.

## Services Actifs

| Container | URL | Rôle |
|---|---|---|
| newt | — | Tunnel sortant vers la passerelle pangolin de skitarii |
| immich-server | photos.friloux.me | Galerie photos auto-hébergée |
| immich-postgres | — | PostgreSQL pour Immich |
| immich-redis | — | Redis pour Immich |

## Exposition Publique

`photos.friloux.me` est un CNAME vers `skitarii.friloux.me` : la passerelle
pangolin le publie, et `newt` porte le trafic par un tunnel sortant jusqu'à
`immich-server` sur le réseau `web` (créé par `docker-newt.nix`). TLS, crowdsec
et les certificats vivent sur skitarii (voir [La Porte](../skitarii/gateway.md)).
clochette ne fait tourner ni traefik ni crowdsec et n'ouvre aucun port web ; SSH
n'est joignable que par Tailscale.

Pas de SSO pangolin sur cette ressource : l'application mobile Immich ne
passerait pas. Immich ne limite pas lui-même les tentatives de connexion, c'est
donc le crowdsec de skitarii qui s'en charge : le scénario
`LePresidente/http-generic-401-bf` bannit les rafales de `POST` répondues en 401.

## Réseau

IPv4 statique (`51.159.34.135/24`) dans `network.nix`. L'IPv6 vient des
annonces du routeur Scaleway (SLAAC) : `2001:bc8:6005:1c:208:a2ff:fe0c:6ca2`,
l'adresse EUI-64 publiée en AAAA de `clochette.friloux.me`.

Les adresses temporaires (confidentialité) sont désactivées
(`networking.tempAddresses`) : Scaleway ne laisse sortir que l'adresse EUI-64,
tout ce qui partait d'une adresse temporaire était perdu — l'IPv6 entrante
marchait, la sortante non (#108).

Les visiteurs IPv6 arrivaient sur le traefik de clochette par `docker-proxy`,
qui notait la passerelle Docker au lieu du visiteur : crowdsec ne pouvait pas
les bannir. Réglé par le passage derrière la passerelle pangolin : le trafic
entre désormais par skitarii, dont le traefik voit le vrai visiteur, IPv4 ou
IPv6.

## Utilisateurs

| Utilisateur | Shell | Rôle |
|---|---|---|
| `guillaume` | fish | Admin système, groupe wheel+docker |
| `weechat` | fish | Session IRC persistante via zellij |

SSH accepte les clés ed25519 et sk-ssh-ed25519 (YubiKey).

## Répertoires de Données

Toutes les données persistantes des containers sont sous `/srv/docker/` :

```text
/srv/docker/
├── photos.friloux.me/
│   ├── upload/       # Photos Immich
│   └── db/           # Données PostgreSQL
```

`traefik/`, `crowdsec.clochette.friloux.me/` et `crowdsec-manager/` restent sur
le disque depuis l'ancienne pile : plus rien ne s'en sert et Borg ne les
sauvegarde plus.

## Backup

Borg backup quotidien vers `ssh://backup@storage2.friloux.me/~/clochette.friloux.me`.

Chemins sauvegardés : `/srv/docker/photos.friloux.me` (sans le `db/` vivant),
`/home/weechat/.config/weechat`.

:::note[Marginalia]
Le datadir PostgreSQL vivant d'Immich (`photos.friloux.me/db`) est **exclu** de Borg.
La base est sauvegardée via le dump nocturne d'Immich dans `upload/backups/` :
voir [Restauration des Données depuis Borg](../operations/restore.md#immich-clochette).
:::
