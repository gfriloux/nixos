---
title: The Ethereal Link — Tailscale Re-enrollment
description: Connecting shrines to the Tailscale mesh after reinstallation or network changes.
---

Procedure to re-enroll a shrine with Tailscale after reinstallation.

## Current Topology

| Shrine | Tailscale Role | SSH Access |
|---|---|---|
| exampleHost | client/admin | via Tailscale or local |
| clochette | exposed server | **only via Tailscale** |
| RogueLeader | internal server | via local network or Tailscale |

SSH to clochette is accessible only from `100.64.0.0/10` (Tailscale subnet).
After reinstall without Tailscale operational, use the serial console.

## Before Reinstalling — Delete Old Entry

From the Tailscale Admin panel:
<https://login.tailscale.com/admin/machines>

Find the shrine (state "offline" or "expired"), then **Delete** or **Expire**.

If not deleted, re-enrollment creates a duplicate with the same hostname.

## Standard Re-enrollment (Interactive Method)

On the shrine to enroll:

```bash
sudo tailscale up
```

Tailscale displays an authentication URL:

```
To authenticate, visit:

        https://login.tailscale.com/a/XXXXXXXXXX
```

Open the URL in a browser, log into Tailscale, approve the shrine.

Verify:

```bash
tailscale status
# The shrine should appear in the list with a 100.x.x.x address
```

## Re-enrollment Without Browser (authkey)

If the server has no graphical interface and the serial console cannot easily display the URL, generate an authkey from the panel:

1. Go to <https://login.tailscale.com/admin/settings/keys>
2. **Generate auth key** → One-time use, no short expiration
3. Copy the key

On the shrine:

```bash
sudo tailscale up --authkey=tskey-auth-XXXXXXXXXXXXXXXX
```

The shrine enrols without browser interaction.

:::note[Marginalia]
Delete the authkey from the panel after use.
:::

## Connectivity Verification

From exampleHost, after enrollment:

```bash
# Global status
tailscale status

# Latency to clochette
tailscale ping clochette

# SSH via Tailscale
ssh guillaume@clochette.friloux.me

# SSH to RogueLeader
ssh guillaume@rogueleader.home
```

## If SSH Remains Inaccessible After Enrollment

On clochette, verify the firewall rule (from serial console):

```bash
# Rule should accept port 22 from 100.64.0.0/10
sudo nft list ruleset | grep -A3 "100.64"
# or
sudo iptables -L INPUT -n | grep 22
```

Verify the Tailscale interface is `tailscale0`:

```bash
ip link show tailscale0
tailscale ip -4
```

If the interface has a different name, verify NixOS config:

```nix
# clochette/default.nix
networking.firewall.trustedInterfaces = ["tailscale0"];
```

## Re-enrollment Without Console Access (Emergency)

If the serial console is unreachable and Tailscale is not operational,
the only option is to temporarily open public SSH.

Edit `clochette/network.nix` to add a temporary rule:

```nix
networking.firewall.extraInputRules = ''
  ip saddr 100.64.0.0/10 tcp dport 22 accept
  ip saddr YOUR.PUBLIC.IP.HERE tcp dport 22 accept  # temporary
'';
```

Deploy from exampleHost, complete Tailscale re-enrollment,
then **immediately** remove the temporary rule and redeploy.
