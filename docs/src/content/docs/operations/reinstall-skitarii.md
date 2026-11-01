---
title: "Reinstall skitarii"
description: From the OVH rescue to the first deploy, with nixos-anywhere from exampleHost.
---

:::danger
Step 4 wipes skitarii's disk. Every public service goes through skitarii:
they are down until the Borg restore (step 8).
:::

| | |
|---|---|
| IP | `5.196.4.180` (DHCP), static IPv6 in `network.nix` |
| Disk | `/dev/sda` in normal boot, **`/dev/sdb` in rescue** |
| Boot | BIOS, GPT + EF02 (`disko.nix`) |
| Console | none (VPS-1, no KVM) |
| sops | age key derived from `/etc/ssh/ssh_host_ed25519_key` |
| SSH | Tailscale only |

## Before

- Access to the OVH manager (reboot in rescue or normal mode).
- The YubiKey (`sops`) and the Tailscale admin console.
- A recent Borg archive: [Restore from Borg](/nixos/operations/restore/).

In rescue, OVH's rescue disk takes `sda` and the VPS disk becomes `sdb`.
disko derives GRUB's device from `disko.nix`: install on `sdb`, then go back
to `sda` (step 6). The `by-id` names follow the SCSI address and move too.

## 1. Temporary changes

Do not commit.

```nix
# disko.nix
device = "/dev/sdb"; # TEMPORARY: reinstall from the rescue

# network.nix
services.openssh.openFirewall = true; # TEMPORARY: not on the tailnet yet
```

## 2. Generate the host key

```bash
mkdir -p /tmp/skitarii-extra/etc/ssh
ssh-keygen -q -t ed25519 -N "" -C root@skitarii -f /tmp/skitarii-extra/etc/ssh/ssh_host_ed25519_key
nix shell nixpkgs#ssh-to-age -c ssh-to-age < /tmp/skitarii-extra/etc/ssh/ssh_host_ed25519_key.pub
ssh-keygen -lf /tmp/skitarii-extra/etc/ssh/ssh_host_ed25519_key.pub   # fingerprint to check at step 5
```

Put the age key in `&server_skitarii` (`.sops.yaml`), then:

```bash
sops updatekeys secrets/skitarii.yaml   # YubiKey
```

## 3. Boot the rescue

OVH manager → the VPS → **Reboot in rescue mode**. OVH sends the root
password. `PubkeyAuthentication=no` keeps the agent's keys out: Debian cuts
the connection after 6 offered keys.

```bash
ssh-keygen -R 5.196.4.180
ssh-copy-id -o PubkeyAuthentication=no -i ~/.ssh/id_ed25519 root@5.196.4.180
```

## 4. Install

```bash
ssh-add ~/.ssh/id_ed25519
nix run github:nix-community/nixos-anywhere -- \
  --flake .#skitarii \
  --target-host root@5.196.4.180 \
  --ssh-option IdentitiesOnly=yes \
  --ssh-option IdentityFile=$HOME/.ssh/id_ed25519.pub \
  --phases kexec,disko,install \
  --extra-files /tmp/skitarii-extra
```

`IdentityFile` on the `.pub`: ssh signs through the agent instead of asking
for the passphrase on every connection. No `reboot` phase: the VPS would
come back in rescue. After `Shared connection closed`, wait, nixos-anywhere
resumes on its own. Expected:

```text
sops-install-secrets: Imported /etc/ssh/ssh_host_ed25519_key as age key with fingerprint age1…
installing the GRUB 2 boot loader on /dev/sdb...
### Done! ###
```

The age fingerprint must match `.sops.yaml`.

## 5. First boot

OVH manager → **Reboot** in normal mode. A minute later:

```bash
ssh-keygen -R 5.196.4.180
ssh -t -o HostName=5.196.4.180 skitarii.friloux.me sudo true
```

Accept only the fingerprint noted at step 2.

## 6. Back to `/dev/sda`

Set `device = "/dev/sda";` back in `disko.nix`, then:

```bash
NIX_SSHOPTS="-o HostName=5.196.4.180" just install_skitarii   # GRUB on /dev/sda
```

## 7. Tailscale

Tailscale admin console: **delete the old skitarii entry** first, otherwise
the node becomes `skitarii-1` and the ssh block points at a dead name.

```bash
sudo tailscale up            # on skitarii, open the URL
```

Then **⋯ → Disable key expiry**. From exampleHost (no `KeyExpiry` =
disabled):

```bash
tailscale status --json | jq '.Peer[] | select(.HostName=="skitarii") | {TailscaleIPs, KeyExpiry}'
ssh-keygen -R skitarii
ssh skitarii.friloux.me true
```

## 8. Close public SSH, restore

Set `openFirewall = false;` back in `network.nix`, then:

```bash
just install_skitarii
nc -zv -w 5 5.196.4.180 22    # must time out
```

Restore pangolin from Borg (nodes, resources, users, TOTP, license,
gerbil's WireGuard key):
[SQLite services (skitarii)](/nixos/operations/restore/#sqlite-services-skitarii).
The Enterprise license follows the host ID: if `/admin/license` shows it
inactive, re-enter it. crowdsec re-registers the bouncer from sops.

Commit `.sops.yaml` and `secrets/skitarii.yaml`, then `rm -r /tmp/skitarii-extra`.

## Troubleshooting

| Symptom | Cause, fix |
|---|---|
| `Connection reset by peer` after a failed login | One-hour ban (`PerSourcePenalties`), in sshd's memory. Reboot from the OVH manager, retry with `IdentitiesOnly`. |
| `skitarii.friloux.me` does not resolve | `NXDOMAIN` cached 3 h (Gandi SOA) at every resolver. Check with `@1.1.1.1`, use `-o HostName=…` meanwhile. |
| Home Manager: `config.fish would be clobbered` | fish created an empty `config.fish` at first login. Delete it, restart `home-manager-guillaume.service`. |

### `sudo` refuses the password

A valid yescrypt hash starts with `$y$j9T$`:

```bash
sops -d --extract '["users"]["guillaume"]["hashed-password"]' secrets/skitarii.yaml | head -c 10; echo
```

Rewrite it without the clipboard:

```bash
sops set secrets/skitarii.yaml '["users"]["guillaume"]["hashed-password"]' "$(mkpasswd -m yescrypt | jq -R .)"
```

Root cannot log in over SSH and `guillaume` has no sudo: no deploy can fix
it. Restart from step 3, with the same `/tmp/skitarii-extra`.
