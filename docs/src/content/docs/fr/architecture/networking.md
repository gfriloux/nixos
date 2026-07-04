---
title: Réseau & Noosphère
description: Topologie du réseau — Tailscale, DNS, réseaux Docker, pare-feu.
---

L'infrastructure se connecte à Internet via clochette seul ; tous les accès inter-machines passent par la noosphère Tailscale.

## Topologie

```text
Internet
    │
    ├── clochette (51.159.34.135)
    │       └── Traefik :80/:443
    │               ├── docs.friloux.me      → papra
    │               ├── wow-cp.friloux.me    → bookstack
    │               └── photos.friloux.me    → immich
    │
    └── Tailscale (100.x.x.x)
            ├── exampleHost
            ├── clochette
            └── RogueLeader
```

## Tailscale

Tous les accès SSH inter-machines passent par Tailscale.
SSH public sur clochette est **fermé** (`openFirewall = false`).

Seul le sous-réseau Tailscale `100.64.0.0/10` peut atteindre le port 22 de clochette :

```nix
networking.firewall.extraInputRules = ''
  ip saddr 100.64.0.0/10 tcp dport 22 accept
'';
```

L'interface Tailscale (`tailscale0`) est également dans `trustedInterfaces`,
ce qui ouvre tous les ports depuis la noosphère Tailscale.

## DNS clochette

Configuration statique (pas de DHCP) :

```text
IP       : 51.159.34.135 / 24
Passerelle: 51.159.34.1
DNS      : 51.159.47.28, 51.159.47.26  (Scaleway)
```

## Réseaux Docker sur clochette

| Réseau | Usage |
|---|---|
| `web` | Réseau partagé Traefik ↔ services exposés |
| `wow-cp` | Réseau interne BookStack ↔ MariaDB ↔ mysqldump |
| `immich` | Réseau interne Immich ↔ PostgreSQL ↔ Redis |

## Ports ouverts sur clochette

| Port | Service |
|---|---|
| 80 | Traefik HTTP (redirige vers 443) |
| 443 | Traefik HTTPS |
| 3000 | crowdsec-manager (interne, bind sur 0.0.0.0 — à restreindre) |

:::caution[Garde]
Scaleway bloque les ports 465 et 587 par défaut.
L'envoi d'e-mails directs ne fonctionne pas.
Toutes les notifications passent par ntfy.sh (HTTPS).
:::
