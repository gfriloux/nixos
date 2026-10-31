---
title: "Papra"
description: "Coffre de documents sur docs.friloux.me."
---

<https://docs.friloux.me>, par la passerelle, sans SSO (il casserait les liens de partage publics). Les connexions sont limitées par better-auth : 3 essais par 10 s sur `/api/auth/sign-in`, par `X-Forwarded-For`. Nix : `docker-papra.nix`.

| | |
|---|---|
| Image | `ghcr.io/papra-hq/papra:*-rootless` |
| Utilisateur | `papra` (UID/GID 65001), aussi propriétaire du fichier env sops |
| Données | `/srv/docker/docs.friloux.me/data/` : `db/` (SQLite, copie pour Borg), `documents/` |
| Secrets | `services/papra/env` via `environmentFiles` |

```bash
# Santé : doit afficher isEverythingOk
docker exec papra bash -c 'exec 3<>/dev/tcp/127.0.0.1/1221 && printf "GET /api/health HTTP/1.0\r\n\r\n" >&3 && cat <&3 | grep isEverythingOk'
```
