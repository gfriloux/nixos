---
title: clochette — Serveur VPS
description: Configuration du VPS Scaleway — services Docker, Traefik, CrowdSec, utilisateurs.
---

VPS Scaleway hébergeant les services web personnels, exposés publiquement via Traefik avec protection WAF CrowdSec.

## Services Actifs

| Container | URL | Rôle |
|---|---|---|
| traefik | — | Reverse proxy, TLS Let's Encrypt |
| crowdsec | — | WAF, protection DDoS, plugin Traefik |
| immich-server | photos.friloux.me | Galerie photos auto-hébergée |
| immich-postgres | — | PostgreSQL pour Immich |
| immich-redis | — | Redis pour Immich |
| crowdsec-manager | :3000 | UI de gestion CrowdSec |

## Réseau

IPv4 statique (`51.159.34.135/24`) dans `network.nix`. L'IPv6 vient des
annonces du routeur Scaleway (SLAAC) : `2001:bc8:6005:1c:208:a2ff:fe0c:6ca2`,
l'adresse EUI-64 publiée en AAAA de `clochette.friloux.me`.

Les adresses temporaires (confidentialité) sont désactivées
(`networking.tempAddresses`) : Scaleway ne laisse sortir que l'adresse EUI-64,
tout ce qui partait d'une adresse temporaire était perdu — l'IPv6 entrante
marchait, la sortante non (#108).

Les visiteurs IPv6 arrivent encore sur traefik par `docker-proxy`, qui note la
passerelle Docker (`172.19.0.1`) au lieu du visiteur : crowdsec ne peut pas les
bannir. Laissé tel quel volontairement, le passage des services de clochette
derrière la passerelle pangolin règle le problème.

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
├── traefik/
│   ├── conf/         # traefik.yml (symlink Nix), traefik_dynamic.yml (sops)
│   ├── acme.json     # Certificats Let's Encrypt
│   └── logs/         # Logs d'accès (rotatés quotidiennement)
├── photos.friloux.me/
│   ├── upload/       # Photos Immich
│   └── db/           # Données PostgreSQL
├── crowdsec.clochette.friloux.me/  # Config et données CrowdSec
└── crowdsec-manager/ # Config et DB crowdsec-manager
```

## Backup

Borg backup quotidien vers `ssh://backup@storage2.friloux.me/~/clochette.friloux.me`.

Chemins sauvegardés : `/srv/docker/traefik`,
`crowdsec*.`, `photos.friloux.me/upload`, `/home/weechat/.config/weechat`.

:::note[Marginalia]
Le datadir PostgreSQL vivant d'Immich (`photos.friloux.me/db`) est **exclu** de Borg.
La base est sauvegardée via le dump nocturne d'Immich dans `upload/backups/` :
voir [Restauration des Données depuis Borg](../operations/restore.md#immich-clochette).
:::
