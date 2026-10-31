---
title: The Noosphere — Networking & DNS
description: Topology, Tailscale integration, firewall rules, and service routing.
---

The Forge connects its shrines across the noosphere through Tailscale, DNS, and sacred firewall rules.

## Topology

```text
Internet
    │
    ├── skitarii (5.196.4.180, 2001:41d0:404:200::487d)
    │       └── gerbil :80/:443 → Traefik → crowdsec bouncer
    │               ├── pangolin.friloux.me  → pangolin
    │               ├── crowdsec.friloux.me  → crowdsec-manager (pangolin SSO)
    │               ├── photos.friloux.me    → newt tunnel → clochette → immich
    │               └── docs, wow-cp, status, cuisine.home, borg-ui
    │                                        → newt tunnel → RogueLeader
    │
    ├── clochette (51.159.34.135)  — no web port, newt dials out
    ├── RogueLeader (192.168.0.10) — no port-forward, newt dials out
    │
    └── Tailscale (100.x.x.x)
            ├── exampleHost
            ├── clochette
            ├── RogueLeader
            └── skitarii
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
| `web` | Shared: newt ↔ published daemons |
| `immich` | Internal: Immich ↔ PostgreSQL ↔ Redis |

## Open Ports on clochette

None on the public interface. `newt` opens an outbound tunnel to the pangolin
gateway on skitarii, which terminates TLS (see [The Gate](../skitarii/gateway.md));
SSH answers on Tailscale only.

## SMTP — Note on Scaleway

Scaleway blocks outbound ports 465 and 587 by default.
Direct email sending does not work.
All omens are heralded via ntfy.sh (HTTPS).
