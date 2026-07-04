---
title: The Noosphere — Networking & DNS
description: Topology, Tailscale integration, firewall rules, and service routing.
---

The Forge connects its shrines across the noosphere through Tailscale, DNS, and sacred firewall rules.

## Topology

```text
Internet
    │
    ├── clochette (51.159.34.135)
    │       └── Traefik :80/:443
    │               ├── wow-cp.friloux.me    → bookstack
    │               └── photos.friloux.me    → immich
    │
    ├── home box (port-forward :80/:443)
    │       └── RogueLeader (192.168.0.10)
    │               └── Traefik :80/:443
    │                       └── docs.friloux.me  → papra
    │
    └── Tailscale (100.x.x.x)
            ├── exampleHost
            ├── clochette
            └── RogueLeader
```

## Tailscale — The Ethereal Link

All inter-shrine SSH passes through Tailscale. Public SSH on clochette is **sealed** (`openFirewall = false`).

Only the Tailscale subnet `100.64.0.0/10` may reach port 22 on clochette:

```nix
networking.firewall.extraInputRules = ''
  ip saddr 100.64.0.0/10 tcp dport 22 accept
'';
```

The Tailscale interface (`tailscale0`) is listed in `trustedInterfaces`, opening all ports from the Tailscale noosphere.

## clochette — DNS Configuration

Static assignment (no DHCP):

```text
IP        : 51.159.34.135 / 24
Gateway   : 51.159.34.1
DNS       : 51.159.47.28, 51.159.47.26  (Scaleway nameservers)
```

## Docker Networks on clochette

| Network | Purpose |
|---|---|
| `web` | Shared: Traefik ↔ exposed daemons |
| `wow-cp` | Internal: BookStack ↔ MariaDB ↔ mysqldump |
| `immich` | Internal: Immich ↔ PostgreSQL ↔ Redis |

## Open Ports on clochette

| Port | Service |
|---|---|
| 80 | Traefik HTTP (redirects to 443) |
| 443 | Traefik HTTPS |
| 3000 | crowdsec-manager (internal, bound to 0.0.0.0 — should be restricted) |

## SMTP — Note on Scaleway

Scaleway blocks outbound ports 465 and 587 by default.
Direct email sending does not work.
All omens are heralded via ntfy.sh (HTTPS).
