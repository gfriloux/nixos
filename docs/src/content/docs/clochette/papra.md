---
title: Papra — Document Management
description: Self-hosted document vault accessible at docs.friloux.me.
---

Papra keeps personal documents safe in a sealed vault. Accessible at https://docs.friloux.me.

## Data Vault

```
/srv/docker/docs.friloux.me/data/
├── db/         # SQLite database
└── documents/  # PDF and document files
```

Owner: system user `papra` (UID/GID 65001).

## Health Check

```bash
curl -s http://localhost:1221/api/health
# Must contain "isEverythingOk"

# Or via container
docker exec papra bash -c 'exec 3<>/dev/tcp/127.0.0.1/1221 && printf "GET /api/health HTTP/1.0\r\n\r\n" >&3 && cat <&3 | grep isEverythingOk'
```

## Secrets

`services/papra/env`: Papra configuration environment variables.
The env file is unsealed by sops and mounted via `environmentFiles`.
Owner: `papra:papra` so the rootless container can read it.

## Active Traefik Middlewares

- `crowdsec@file` — WAF protection
- `rate-limit@file` — standard rate limiting
- `rate-limit-strict@file` — strict limiting on `/login`
- `security-headers@file` — HTTP security headers
