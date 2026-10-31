---
title: Papra
description: Gestionnaire de documents — configuration, health check, secrets, exposition.
---

Gestionnaire de documents auto-hébergé exposé à <https://docs.friloux.me>.

## Données

```text
/srv/docker/docs.friloux.me/data/
├── db/         # Base de données SQLite
└── documents/  # Fichiers PDF et documents
```

Propriétaire : utilisateur système `papra` (UID/GID 65001).

## Health Check

```bash
curl -s http://localhost:1221/api/health
# Doit contenir "isEverythingOk"

# Ou via le container
docker exec papra bash -c 'exec 3<>/dev/tcp/127.0.0.1/1221 && printf "GET /api/health HTTP/1.0\r\n\r\n" >&3 && cat <&3 | grep isEverythingOk'
```

## Secrets

`services/papra/env` : variables d'environnement de configuration Papra.
Le fichier env est déchiffré par sops et monté via `environmentFiles`.
Propriétaire : `papra:papra` pour que le container rootless puisse le lire.

## Exposition

Publié par la passerelle pangolin de skitarii (sans SSO, qui casserait les liens
de partage publics), crowdsec côté skitarii. La connexion est limitée par
better-auth lui-même : 3 essais par 10 secondes sur `/api/auth/sign-in`, par IP
du visiteur lue dans `X-Forwarded-For`.
