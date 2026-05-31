# Machines & systèmes

## exampleHost

| Paramètre | Valeur |
|---|---|
| Rôle | Poste de travail principal |
| OS | NixOS, kernel 6.18 |
| CPU | x86_64 |
| GPU | AMD (pilote `amdgpu`, ROCM) |
| Disques système | 2× Samsung SSD 980 PRO 1 To NVMe (ZFS miroir) |
| Disque données | 1× HDD `/data2` ext4 (nofail) |
| Affichage | KDE Plasma 6, Wayland, SDDM |
| hostId ZFS | `21ed29b1` |
| stateVersion | `24.11` |

Services système notables :
- Docker (storage driver ZFS)
- zrepl (pull de backups depuis storage2.retrohive.fr)
- Tailscale
- pcscd (YubiKey)
- pipewire

## clochette

| Paramètre | Valeur |
|---|---|
| Rôle | VPS exposé — services web personnels |
| Hébergeur | Scaleway |
| IP publique | `51.159.34.135` |
| OS | NixOS |
| CPU | x86_64, Intel KVM |
| Disque | `/dev/sda`, ext4 (MBR) |
| SSH | Uniquement via Tailscale (`100.64.0.0/10`) |
| stateVersion | `26.05` |

Services Docker :

| Container | Domaine | Rôle |
|---|---|---|
| traefik | — | Reverse proxy + TLS Let's Encrypt |
| crowdsec | — | WAF / protection DDoS |
| papra | docs.friloux.me | Gestion documentaire |
| wow-cp-bookstack | wow-cp.friloux.me | Wiki |
| wow-cp-mariadb | — | Base de données BookStack |
| wow-cp-mysqldump | — | Backup SQL cron |
| immich-server | photos.friloux.me | Galerie photos |
| immich-postgres | — | Base de données Immich |
| immich-redis | — | Cache Immich |
| crowdsec-manager | :3000 (interne) | UI de gestion CrowdSec |

## RogueLeader

| Paramètre | Valeur |
|---|---|
| Rôle | Serveur dédié domestique |
| OS | NixOS |
| CPU | x86_64 |
| Disque | `/dev/sda`, ext4 (disko, GPT) |
| sops | Clé age dérivée de la clé SSH host |
| stateVersion | `25.11` |

Services Docker : borg-ui, mealie, uptime-kuma.
