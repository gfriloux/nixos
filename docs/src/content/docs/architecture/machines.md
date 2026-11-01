---
title: "Machines"
description: The four machines in one table, with a link to each one's page.
---

| | exampleHost | clochette | skitarii | RogueLeader |
|---|---|---|---|---|
| Role | Workstation | Immich | Web gateway | Personal services |
| Where | Home | Scaleway | OVH VPS-1 | Home |
| Public IP | | `51.159.34.135` | `5.196.4.180`, `2001:41d0:404:200::487d` | |
| Disk | ZFS mirror (2× NVMe 980 PRO), `/data2` ext4 | ext4, MBR | ext4, disko, GPT/BIOS | ext4, disko, GPT |
| sops key | `/etc/sops/age/keys.txt` | SSH host key | SSH host key | SSH host key |
| SSH | local | Tailscale | Tailscale | LAN |
| stateVersion | `24.11` | `26.05` | `26.05` | `25.11` |
| Details | [exampleHost](/nixos/examplehost/overview/) | [clochette](/nixos/clochette/overview/) | [skitarii](/nixos/skitarii/overview/) | [RogueLeader](/nixos/rogueleader/overview/) |

Containers: on each machine's page.
Web flow: [Gateway](/nixos/skitarii/gateway/).
