---
title: The Sentinel — CrowdSec WAF & DDoS Guard
description: Real-time threat detection, bouncer plugin for Traefik, decision management.
---

The Sentinel (`docker-crowdsec`) stands vigilant at the noosphere's edge, analyzing logs and blocking malicious IPs in real-time.

## How It Works

CrowdSec analyzes Traefik logs (`/srv/docker/traefik/logs/traefik.log`)
and maintains a decision list (bans, captchas). The Traefik bouncer plugin
`crowdsec-bouncer-traefik-plugin` consults CrowdSec in real-time to block IPs.

`crowdsec-manager` provides a web UI on port 3000 (internal).

## Health Check

```bash
curl -s http://localhost:8080/health
# or
docker exec crowdsec wget -q -O /dev/null http://localhost:8080/health
```

## Useful cscli Commands

```bash
# Enter the CrowdSec container
docker exec -it crowdsec sh

# List active decisions (bans)
cscli decisions list

# Ban an IP manually
cscli decisions add --ip 1.2.3.4 --duration 24h --reason "manual test"

# Lift a ban
cscli decisions delete --ip 1.2.3.4

# View recent alerts
cscli alerts list

# Status of installed collections
cscli collections list
```

## Persistent Data

```text
/srv/docker/crowdsec.clochette.friloux.me/
├── data/    # SQLite database, GeoIP
└── etc/     # Configuration, parsers, scenarios, decisions
```

These directories are included in Borg backup.

## Traefik Dependency

Traefik requires CrowdSec at startup:

```nix
systemd.services.traefik = {
  after = ["crowdsec.service"];
  requires = ["crowdsec.service"];
};
```

If CrowdSec fails to start, temporarily disable this dependency to diagnose:

```bash
systemctl edit docker-traefik
# Add [Unit] section, remove CrowdSec-related After/Requires
# Warning: temporary only — revert to Nix config afterwards
```
