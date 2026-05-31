---
title: Traefik
description: Reverse proxy — TLS, routage HTTP, intégration CrowdSec.
---

Le Gardien qui expose les services web derrière un reverse proxy sécurisé avec TLS Let's Encrypt et protection WAF.

## Configuration

- Config statique : `traefik.yml` généré par Nix (symlink `L+` vers le store)
- Config dynamique : `traefik_dynamic.yml` déchiffrée par sops vers `/srv/docker/traefik/conf/`
- Certificats : `acme.json` (permissions `0600` obligatoires)
- Logs d'accès : `/srv/docker/traefik/logs/traefik.log` (JSON, rotatés quotidiennement 14j)

## Entrypoints

| Entrypoint | Port | Rôle |
|---|---|---|
| `web` | 80 | Redirect HTTPS |
| `websecure` | 443 | TLS, timeout 600s |
| `traefik` | 127.0.0.1:8080 | API/dashboard/ping (local uniquement) |

## Health Check

```bash
docker exec traefik traefik healthcheck
# ou
curl -s http://127.0.0.1:8080/ping
```

## Ajouter un Nouveau Service derrière Traefik

Dans le fichier `docker-*.nix` du service, ajouter les labels :

```nix
labels = {
  "traefik.enable" = "true";
  "traefik.http.routers.<nom>.rule" = "Host(`monservice.friloux.me`)";
  "traefik.http.routers.<nom>.tls" = "true";
  "traefik.http.routers.<nom>.tls.certresolver" = "lets-encrypt";
  "traefik.docker.network" = "web";
  "traefik.http.services.<nom>.loadbalancer.server.port" = "PORT";
  "traefik.http.routers.<nom>.middlewares" = "crowdsec@file,rate-limit@file,security-headers@file";
  "friloux.me/health-watch" = "true";  # toujours en dernier
};
networks = ["web"];
```

## Dépendance CrowdSec

Traefik ne démarre qu'après CrowdSec (`after = ["crowdsec.service"]`).
Si CrowdSec est en erreur, Traefik ne démarrera pas.

## Renouvellement des Certificats

Let's Encrypt renouvelle automatiquement via TLS challenge.
En cas de problème :

```bash
# Voir les logs de renouvellement
docker logs traefik 2>&1 | grep -i "acme\|cert\|renew"

# Forcer un renouvellement (supprimer le cert existant)
# Attention : Let's Encrypt limite à 5 tentatives/domaine/heure
docker stop traefik
rm /srv/docker/traefik/acme.json
touch /srv/docker/traefik/acme.json && chmod 600 /srv/docker/traefik/acme.json
docker start traefik
```
