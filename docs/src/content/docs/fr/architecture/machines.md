---
title: "Machines"
description: Les quatre machines en un tableau, avec un lien vers la page de chacune.
---

| | exampleHost | clochette | skitarii | RogueLeader |
|---|---|---|---|---|
| Rôle | Poste de travail | Immich | Passerelle web | Services perso |
| Où | Maison | Scaleway | OVH VPS-1 | Maison |
| IP publique | | `51.159.34.135` | `5.196.4.180`, `2001:41d0:404:200::487d` | |
| Disque | ZFS miroir (2× NVMe 980 PRO), `/data2` ext4 | ext4, MBR | ext4, disko, GPT/BIOS | ext4, disko, GPT |
| Clé sops | `/etc/sops/age/keys.txt` | clé SSH d'hôte | clé SSH d'hôte | clé SSH d'hôte |
| SSH | local | Tailscale | Tailscale | LAN |
| stateVersion | `24.11` | `26.05` | `26.05` | `25.11` |
| Détail | [exampleHost](/nixos/fr/examplehost/overview/) | [clochette](/nixos/fr/clochette/overview/) | [skitarii](/nixos/fr/skitarii/overview/) | [RogueLeader](/nixos/fr/rogueleader/overview/) |

Conteneurs : sur la page de chaque machine.
Flux web : [Passerelle](/nixos/fr/skitarii/gateway/).
