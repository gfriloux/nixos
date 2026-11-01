---
title: "skitarii"
description: OVH VPS-1, the pangolin gateway. SSH over Tailscale only.
sidebar:
  order: 1
  label: "Overview"
---

Single public entry point: [Gateway](/nixos/skitarii/gateway/).

| | |
|---|---|
| Host | OVH VPS-1 (4 GB RAM, 40 GB disk) |
| IPv4 | `5.196.4.180` (DHCP) |
| IPv6 | `2001:41d0:404:200::487d/128` static, gateway `2001:41d0:404:200::1` |
| DNS | `skitarii.friloux.me` A + AAAA at Gandi (by hand). `pangolin`, `crowdsec` are CNAMEs to it |
| Tailscale | `100.118.203.120`, key expiry disabled |
| Disk | `/dev/sda`, GPT via disko: 1M BIOS boot, 2G swap, ext4 `/`. GRUB, BIOS |
| sops | age key from `/etc/ssh/ssh_host_ed25519_key` |
| STC relics | `hardening.ssh`, `nixHousekeeping` |
| SSH | Tailscale only (`openFirewall = false`, `tailscale0` trusted) |
| `guillaume` | YubiKey `sk-ssh-ed25519` (application `ssh:skitarii`, handle in `kuri_exampleHost.yaml`) + perso key. Password hash in `secrets/skitarii.yaml` |
| Home Manager | `guillaume@skitarii` (cogitator-enginseer) |
| stateVersion | `26.05` |

## Deploy

```bash
just build_skitarii
just install_skitarii    # through the tailnet (ssh block HostName = skitarii)
just secrets_skitarii    # edit secrets/skitarii.yaml
```

## Watch out

- **No KVM console.** SSH and Tailscale both gone: OVH rescue mode only, see [Reinstall skitarii](/nixos/operations/reinstall-skitarii/).
- **One failed SSH auth = 1 h ban** for the source address (`PerSourcePenalties = authfail:3600s`). The ssh block pins the key (`IdentitiesOnly`). A reboot clears the ban (it lives in sshd's memory).
- **First switch adding the IPv6 addresses:** start `network-addresses-ens3` by hand. At boot it starts on its own.
