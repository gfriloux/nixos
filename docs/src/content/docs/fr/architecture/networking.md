---
title: Réseau & Noosphère
description: Topologie du réseau — Tailscale, DNS, réseaux Docker, pare-feu.
---

L'infrastructure s'expose à Internet via la passerelle pangolin de skitarii, que clochette et RogueLeader joignent par un tunnel sortant ; tous les accès inter-machines passent par la noosphère Tailscale.

## Topologie

```text
Internet
    │
    ├── skitarii (5.196.4.180, 2001:41d0:404:200::487d)
    │       └── gerbil :80/:443 → Traefik → crowdsec bouncer
    │               ├── pangolin.friloux.me  → pangolin
    │               ├── crowdsec.friloux.me  → crowdsec-manager (pangolin SSO)
    │               ├── photos.friloux.me    → tunnel newt → clochette → immich
    │               └── docs, wow-cp, status, cuisine.home, borg-ui
    │                                        → tunnel newt → RogueLeader
    │
    ├── clochette (51.159.34.135)  — aucun port web, newt sort
    ├── RogueLeader (192.168.0.10) — aucune redirection de port, newt sort
    │
    └── Tailscale (100.x.x.x)
            ├── exampleHost
            ├── clochette
            ├── RogueLeader
            └── skitarii
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
| `web` | Réseau partagé newt ↔ services publiés |
| `immich` | Réseau interne Immich ↔ PostgreSQL ↔ Redis |

## Ports ouverts sur clochette

Aucun sur l'interface publique. `newt` ouvre un tunnel sortant vers la
passerelle pangolin de skitarii, qui termine le TLS (voir
[La Porte](../skitarii/gateway.md)) ; SSH ne répond que par Tailscale.

:::caution[Garde]
Scaleway bloque les ports 465 et 587 par défaut.
L'envoi d'e-mails directs ne fonctionne pas.
Toutes les notifications passent par ntfy.sh (HTTPS).
:::
