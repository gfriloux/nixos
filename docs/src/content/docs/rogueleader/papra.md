---
title: "Papra"
description: "Document vault at docs.friloux.me."
---

<https://docs.friloux.me>, through the gateway, no SSO (it would break public share links). Sign-in is rate-limited by better-auth: 3 tries per 10 s on `/api/auth/sign-in`, keyed on `X-Forwarded-For`. Nix: `docker-papra.nix`.

| | |
|---|---|
| Image | `ghcr.io/papra-hq/papra:*-rootless` |
| User | `papra` (UID/GID 65001), also owner of the sops env file |
| Data | `/srv/docker/docs.friloux.me/data/`: `db/` (SQLite, snapshot for Borg), `documents/` |
| Secrets | `services/papra/env` via `environmentFiles` |

```bash
# Health: must print isEverythingOk
docker exec papra bash -c 'exec 3<>/dev/tcp/127.0.0.1/1221 && printf "GET /api/health HTTP/1.0\r\n\r\n" >&3 && cat <&3 | grep isEverythingOk'
```
