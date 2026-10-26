---
title: skitarii — The Gate-Shrine
description: OVH VPS-1, future pangolin gateway. Base system only for now — SSH over Tailscale, sops, static IPv6.
---

Behold skitarii — the gate-shrine, raised on an OVH VPS-1 to stand one day
before every other shrine as their single point of entry.

## Configuration

| Parameter | Value |
|---|---|
| Role | Future gateway (pangolin, gerbil, traefik, crowdsec, crowdsec-manager) |
| Host | OVH VPS-1 (4 GB RAM, 40 GB disk) |
| Public IPv4 | `5.196.4.180` (DHCP) |
| Public IPv6 | `2001:41d0:404:200::487d/128` (static, gateway `2001:41d0:404:200::1`) |
| DNS | `skitarii.friloux.me` — A + AAAA at Gandi, set by hand |
| Tailscale | `100.118.203.120`, key expiry disabled |
| Boot | BIOS, GRUB on `/dev/sda` |
| Storage | `/dev/sda`, GPT via disko: 1M BIOS boot, 2G swap, ext4 `/` |
| sops | Age key derived from `/etc/ssh/ssh_host_ed25519_key` |
| stateVersion | `26.05` |

## Current State

No daemon is bound yet. The shrine carries only the base system:

- STC relics `hardening.ssh` and `nixHousekeeping`
- SSH reachable **only through Tailscale** (`openFirewall = false`, `tailscale0` trusted)
- user `guillaume`: keys `sk-ssh-ed25519` (YubiKey, application `ssh:skitarii`,
  handle under passphrase in `kuri_exampleHost.yaml`) and the perso key;
  password hash in `secrets/skitarii.yaml`
- Home Manager `guillaume@skitarii` (cogitator-enginseer), wired in by snowfall

The daemons will be bound one at a time.

## Deployment

```bash
just build_skitarii
just install_skitarii    # through the tailnet (ssh block HostName = skitarii)
just secrets_skitarii    # edit secrets/skitarii.yaml
```

## Important Notes

- **No KVM console on a VPS-1.** If SSH and Tailscale are both gone, the only
  way in is the OVH rescue mode — see
  [Rite of Resurrection: skitarii](../operations/reinstall-skitarii.md).
- **One failed SSH authentication costs one hour of ban** for the source
  address (`PerSourcePenalties = authfail:3600s` from the ssh relic). The
  ssh block pins the key with `IdentitiesOnly`, so it never happens through
  `ssh skitarii.friloux.me`. Rebooting the VPS clears the ban: it lives in
  sshd's memory.
- After a first switch that adds the IPv6 addresses, start
  `network-addresses-ens3` by hand: it is tied to the interface showing up,
  which already happened. At boot it starts on its own.
