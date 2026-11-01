---
title: "Tailscale"
description: Who is on the tailnet, enrolling a machine, what to do without SSH.
---

Tailscale SaaS, GitHub account `gfriloux`.

| Machine | Tailnet | SSH |
|---|---|---|
| exampleHost | yes | local |
| clochette | yes, `clochette` | tailnet only (`100.64.0.0/10` + trusted `tailscale0`) |
| skitarii | yes, `skitarii` | tailnet only (trusted `tailscale0`) |
| RogueLeader | **no** | LAN, `192.168.0.10` |

exampleHost's ssh block targets the MagicDNS names (`HostName = "clochette"`).

## Enroll

1. [Admin console](https://login.tailscale.com/admin/machines): delete the
   old entry, otherwise the node becomes `clochette-1` and the ssh block
   points at a dead name.
2. On the machine: `sudo tailscale up`, open the URL.
3. Admin console, on the line: **⋯ → Disable key expiry**.
4. From exampleHost:

```bash
tailscale status --json | jq '.Peer[] | select(.HostName=="clochette") | {TailscaleIPs, KeyExpiry}'   # no KeyExpiry = disabled
ssh-keygen -R clochette
ssh clochette.friloux.me true
```

No browser: [generate a one-time auth key](https://login.tailscale.com/admin/settings/keys),
`sudo tailscale up --authkey=tskey-auth-…`, then delete it.

## Without SSH

The tailnet is the only SSH door to clochette and skitarii: without it, no
deploy gets through.

| Machine | Fallback |
|---|---|
| clochette | Dedibox serial console, login `guillaume`, `sudo tailscale up` |
| skitarii | No console: [reinstall](/nixos/operations/reinstall-skitarii/) |

Diagnosis, once connected:

```bash
tailscale status
ip link show tailscale0
sudo nft list ruleset | grep -A3 100.64     # clochette
```
