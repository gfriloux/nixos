# Papra

Gestionnaire de documents auto-hébergé. URL : <https://docs.friloux.me>

## Données

```
/srv/docker/docs.friloux.me/data/
├── db/         # Base de données SQLite
└── documents/  # Fichiers PDF et documents
```

Propriétaire : utilisateur système `papra` (UID/GID 65001).

## Health check

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

## Middlewares Traefik actifs

- `crowdsec@file` — protection WAF
- `rate-limit@file` — limitation de débit standard
- `rate-limit-strict@file` — limitation stricte sur `/login`
- `security-headers@file` — en-têtes de sécurité HTTP
