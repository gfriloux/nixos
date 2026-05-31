---
title: Design & Prerequisites — RogueLeader Architecture
description: Disk partitioning with disko, local network access, and future enhancements.
---

The foundational design of RogueLeader — how storage is ordained and access is granted.

## Disk Partitioning (disko)

Single disk `/dev/sda`, GPT:

| Partition | Size | Role |
|---|---|---|
| 1 MB | BIOS boot | GRUB |
| 4 GB | swap | — |
| remainder | `/` ext4 | System + data |

## Access

Local network: `192.168.0.10` (alias `rogueleader.home` in exampleHost's `ssh.nix`).
Deploy from exampleHost via local SSH.

## Planned Enhancements

- Document RogueLeader-specific reinstallation procedures
- Validate age key rotation procedure post-reinstall
- Consider adding Tailscale for remote access independent of local network
