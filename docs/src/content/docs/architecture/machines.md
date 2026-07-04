---
title: The Three Machine-Shrines
description: Details of exampleHost, clochette, and RogueLeader — their hardware, roles, and bound daemons.
---

Behold the three shrines that form the KURI Forge: the workstation where the Techpriest labours, the VPS where daemons serve the noosphere, and the home-shrine that tends the archive.

## exampleHost — The Workstation-Shrine

| Parameter | Value |
|---|---|
| Role | Primary workstation-shrine |
| OS | NixOS, kernel 6.18 |
| CPU | x86_64 |
| GPU | AMD (driver `amdgpu`, ROCM) |
| System disks | 2× Samsung SSD 980 PRO 1 TB NVMe (ZFS mirror) |
| Data disk | 1× HDD `/data2` ext4 (nofail) |
| Display | KDE Plasma 6, Wayland, SDDM |
| ZFS hostId | `21ed29b1` |
| stateVersion | `24.11` |

**Notable bound daemons and services:**

- Docker (storage driver: ZFS)
- zrepl (pulls snapshots from storage2.retrohive.fr)
- Tailscale
- pcscd (YubiKey)
- pipewire

## clochette — The VPS-Shrine

| Parameter | Value |
|---|---|
| Role | Exposed shrine — personal web services |
| Host | Scaleway |
| Public IP | `51.159.34.135` |
| OS | NixOS |
| CPU | x86_64, Intel KVM |
| Storage | `/dev/sda`, ext4 (MBR) |
| SSH Access | Tailscale only (`100.64.0.0/10`) |
| stateVersion | `26.05` |

**Bound daemons:**

| Daemon | Domain | Role |
|---|---|---|
| traefik | — | Reverse proxy, TLS (Let's Encrypt) |
| crowdsec | — | WAF / DDoS guard |
| wow-cp-bookstack | wow-cp.friloux.me | Wiki |
| wow-cp-mariadb | — | BookStack database |
| wow-cp-mysqldump | — | Database backup cron |
| immich-server | photos.friloux.me | Photo gallery |
| immich-postgres | — | Immich database |
| immich-redis | — | Immich cache |
| crowdsec-manager | :3000 (internal) | CrowdSec UI |

## RogueLeader — The Home-Shrine

| Parameter | Value |
|---|---|
| Role | Dedicated home-shrine |
| OS | NixOS |
| CPU | x86_64 |
| Storage | `/dev/sda`, ext4 (disko, GPT) |
| sops | Age key derived from SSH host key |
| stateVersion | `25.11` |

**Bound daemons:** borg-ui, mealie, uptime-kuma, and papra
(docs.friloux.me — exposed publicly through Traefik + CrowdSec, reached
via a box port-forward of 80/443 to 192.168.0.10).
