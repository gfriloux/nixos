# clochette — serveur

VPS Scaleway hébergeant les services web personnels.

## Services actifs

| Container | URL | Rôle |
|---|---|---|
| traefik | — | Reverse proxy, TLS Let's Encrypt |
| crowdsec | — | WAF, protection DDoS, plugin Traefik |
| papra | docs.friloux.me | Gestion documentaire |
| wow-cp-bookstack | wow-cp.friloux.me | Wiki |
| wow-cp-mariadb | — | Base MariaDB pour BookStack |
| wow-cp-mysqldump | — | Dump SQL quotidien |
| immich-server | photos.friloux.me | Galerie photos auto-hébergée |
| immich-postgres | — | PostgreSQL pour Immich |
| immich-redis | — | Redis pour Immich |
| crowdsec-manager | :3000 | UI de gestion CrowdSec |

## Utilisateurs

| Utilisateur | Shell | Rôle |
|---|---|---|
| `guillaume` | fish | Admin système, groupe wheel+docker |
| `weechat` | fish | Session IRC persistante via zellij |

SSH accepte les clés ed25519 et sk-ssh-ed25519 (YubiKey).

## Répertoires de données

Toutes les données persistantes des containers sont sous `/srv/docker/` :

```
/srv/docker/
├── traefik/
│   ├── conf/         # traefik.yml (symlink Nix), traefik_dynamic.yml (sops)
│   ├── acme.json     # Certificats Let's Encrypt
│   └── logs/         # Logs d'accès (rotatés quotidiennement)
├── docs.friloux.me/  # Données Papra
├── wow-cp.friloux.me/
│   ├── data/         # Fichiers BookStack
│   ├── db/           # Données MariaDB
│   └── dumps/        # Dumps SQL mysqldump
├── photos.friloux.me/
│   ├── upload/       # Photos Immich
│   └── db/           # Données PostgreSQL
├── crowdsec.clochette.friloux.me/  # Config et données CrowdSec
└── crowdsec-manager/ # Config et DB crowdsec-manager
```

## Backup

Borg backup quotidien vers `ssh://backup@storage2.friloux.me/~/clochette.friloux.me`.

Chemins sauvegardés : `/srv/docker/traefik`, `docs.friloux.me`, `wow-cp.friloux.me`,
`crowdsec*.`, `photos.friloux.me/upload`, `/home/weechat/.config/weechat`.

> Les données PostgreSQL Immich (`photos.friloux.me/db`) sont **incluses** dans le backup.
> Pour une restauration propre d'Immich, préférer un dump pg_dump avant restauration Borg.
