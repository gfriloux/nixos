---
title: Sanctuaires-Machines
description: Spécifications des trois sanctuaires-machines — exampleHost, clochette, RogueLeader.
---

L'infrastructure consiste en trois hôtes consacrés, chacun ayant un rôle distinct et une configuration propre.

## exampleHost

| Paramètre | Valeur |
|---|---|
| Rôle | Sanctuaire de travail principal |
| OS | NixOS, kernel 6.18 |
| CPU | x86_64 |
| GPU | AMD (pilote `amdgpu`, ROCM) |
| Disques système | 2× Samsung SSD 980 PRO 1 To NVMe (miroir ZFS) |
| Disque données | 1× HDD `/data2` ext4 (nofail) |
| Affichage | KDE Plasma 6, Wayland, SDDM |
| hostId ZFS | `21ed29b1` |
| stateVersion | `24.11` |

Services système notables :

- Docker (storage driver ZFS)
- zrepl (tir de backups depuis storage2.retrohive.fr)
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

Services Docker : borg-ui, mealie, uptime-kuma, papra
(docs.friloux.me), ainsi que la stack BookStack wow-cp (wow-cp.friloux.me —
bookstack + mariadb + mysqldump). papra et BookStack sont tous deux exposés
publiquement via Traefik + CrowdSec, atteints par une redirection de port
80/443 de la box vers 192.168.0.10.
