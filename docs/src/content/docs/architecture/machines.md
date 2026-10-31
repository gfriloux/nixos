---
title: The Four Machine-Shrines
description: Details of exampleHost, clochette, RogueLeader, and skitarii — their hardware, roles, and bound daemons.
---

Behold the four shrines that form the KURI Forge: the workstation where the Techpriest labours, the VPS where daemons serve the noosphere, the home-shrine that tends the archive, and the gate-shrine that will one day guard them all.

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
| newt | — | Outbound tunnel to the pangolin gateway on skitarii |
| immich-server | photos.friloux.me | Photo gallery |
| immich-postgres | — | Immich database |
| immich-redis | — | Immich cache |

## RogueLeader — The Home-Shrine

| Parameter | Value |
|---|---|
| Role | Dedicated home-shrine |
| OS | NixOS |
| CPU | x86_64 |
| Storage | `/dev/sda`, ext4 (disko, GPT) |
| sops | Age key derived from SSH host key |
| stateVersion | `25.11` |

**Bound daemons:** borg-ui, mealie, uptime-kuma, papra
(docs.friloux.me), and the wow-cp BookStack stack (wow-cp.friloux.me —
bookstack + mariadb + mysqldump). Every web daemon is published by the pangolin
gateway on skitarii through RogueLeader's `newt` tunnel; no port-forward on the
box.

## skitarii — The Gate-Shrine

| Parameter | Value |
|---|---|
| Role | Gateway (pangolin, POC) |
| Host | OVH VPS-1 |
| Public IP | `5.196.4.180`, `2001:41d0:404:200::487d` |
| OS | NixOS |
| Storage | `/dev/sda`, ext4 (disko, GPT, BIOS) |
| SSH Access | Tailscale only |
| sops | Age key derived from SSH host key |
| stateVersion | `26.05` |

**Bound daemons:** pangolin (pangolin.friloux.me), gerbil, traefik, crowdsec,
crowdsec-manager (crowdsec.friloux.me, behind pangolin SSO). See
[The Gate](../skitarii/gateway.md).
