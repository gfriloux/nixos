---
title: Rite of Resurrection — skitarii
description: Reinstalling the OVH VPS from the rescue mode with nixos-anywhere — host key, disk naming, Tailscale.
---

Complete guide to resurrect the skitarii gate-shrine. OVH offers no NixOS
image and a VPS-1 has no KVM console: everything goes through the **rescue
mode** and nixos-anywhere, run from exampleHost.

:::caution[Ward]
SSH on skitarii is Tailscale-only. A fresh install is not on the tailnet
yet, so public SSH is reopened for the duration of the rite (step 1) and
sealed again at the end (step 8). Do not skip the last step.
:::

## Reference Information

| Parameter | Value |
|---|---|
| Public IPv4 | `5.196.4.180` |
| Disk | `/dev/sda` in normal boot, **`/dev/sdb` in rescue** |
| Boot | BIOS, GRUB (GPT + EF02 partition via disko) |
| sops | Age key derived from `/etc/ssh/ssh_host_ed25519_key` |
| SSH after the rite | Tailscale only, `ssh skitarii.friloux.me` |

## Prerequisites

- [ ] Access to the OVH manager (reboot in rescue / normal mode)
- [ ] The YubiKey (age identity for `sops`, ssh key `ssh:skitarii`)
- [ ] Access to the Tailscale admin console (sign in with GitHub, `gfriloux`)

## Why the Disk Name Moves

In rescue mode, OVH attaches its own rescue disk as `sda`; the VPS disk
becomes `sdb`. In normal boot it is `sda` again. The `/dev/disk/by-id`
names do not help: they follow the SCSI address, which changes too.

disko derives `boot.loader.grub.devices` from its `device`, so the install
must target `/dev/sdb` and the config must go back to `/dev/sda` before the
next switch — otherwise `grub-install` runs against a disk that does not
exist.

## Step 1 — Temporary Changes in the Flake

In `systems/x86_64-linux/skitarii/disko.nix`:

```nix
device = "/dev/sdb"; # TEMPORARY: reinstall from the rescue
```

In `systems/x86_64-linux/skitarii/network.nix`:

```nix
services.openssh.openFirewall = true; # TEMPORARY: not on the tailnet yet
```

Do not commit these.

## Step 2 — Generate the Host Key Beforehand

The host key decides the age key, so it is created on exampleHost and
handed to the installer: sops works from the very first boot.

```bash
mkdir -p /tmp/skitarii-extra/etc/ssh
ssh-keygen -q -t ed25519 -N "" -C root@skitarii -f /tmp/skitarii-extra/etc/ssh/ssh_host_ed25519_key
nix shell nixpkgs#ssh-to-age -c ssh-to-age < /tmp/skitarii-extra/etc/ssh/ssh_host_ed25519_key.pub
```

Replace the `&server_skitarii` value in `.sops.yaml` with that age key, then
re-encrypt (YubiKey):

```bash
sops updatekeys secrets/skitarii.yaml
```

Note the new fingerprint, to check it at first connection:

```bash
ssh-keygen -lf /tmp/skitarii-extra/etc/ssh/ssh_host_ed25519_key.pub
```

## Step 3 — Boot the Rescue

OVH manager → the VPS → **Reboot in rescue mode**. The rescue root password
is given by OVH.

From exampleHost, copy the key into the rescue. `PubkeyAuthentication=no`
skips the agent's keys: Debian cuts the connection after 6 offered keys.

```bash
ssh-keygen -R 5.196.4.180
ssh-copy-id -o PubkeyAuthentication=no -i ~/.ssh/id_ed25519 root@5.196.4.180
```

## Step 4 — Install with nixos-anywhere

:::danger[Interdict]
Destructive and irreversible. Erases the VPS disk entirely.
:::

```bash
nix run github:nix-community/nixos-anywhere -- \
  --flake .#skitarii \
  --target-host root@5.196.4.180 \
  --ssh-option IdentitiesOnly=yes \
  --ssh-option IdentityFile=$HOME/.ssh/id_ed25519.pub \
  --phases kexec,disko,install \
  --extra-files /tmp/skitarii-extra
```

- `IdentityFile` points to the **`.pub`**: ssh asks the agent to sign
  instead of prompting the passphrase at each of nixos-anywhere's many
  connections. Run `ssh-add ~/.ssh/id_ed25519` first.
- No `reboot` phase: the VPS would come back in rescue.
- After `machine will boot into nixos in 6s...` and `Shared connection
  closed`, **wait**: nixos-anywhere is waiting for the installer to come up,
  then carries on alone.

Expected at the end:

```text
sops-install-secrets: Imported /etc/ssh/ssh_host_ed25519_key as age key with fingerprint age1…
installing the GRUB 2 boot loader on /dev/sdb...
### Done! ###
```

The age fingerprint must be the one written in `.sops.yaml`.

## Step 5 — First Boot

OVH manager → **Reboot** in normal mode (leaving the rescue). About a minute
later:

```bash
ssh-keygen -R 5.196.4.180
ssh -t -o HostName=5.196.4.180 skitarii.friloux.me sudo true
```

Accept only the fingerprint noted at step 2. If `sudo` refuses the
password, see [Troubleshooting](#troubleshooting).

## Step 6 — Back to `/dev/sda`

Revert `disko.nix` to `device = "/dev/sda";`, then:

```bash
NIX_SSHOPTS="-o HostName=5.196.4.180" just install_skitarii
```

Expected: `installing the GRUB 2 boot loader on /dev/sda...`.

## Step 7 — Tailscale

In the [admin console](https://login.tailscale.com/admin/machines),
**delete the old skitarii entry first**: otherwise the new node is named
`skitarii-1` and the MagicDNS name `skitarii` used by the ssh block points
nowhere.

On skitarii:

```bash
sudo tailscale up
```

Open the URL, approve, then on the skitarii line: **⋯ → Disable key
expiry**. Verify from exampleHost (no `KeyExpiry` means disabled):

```bash
tailscale status --json | jq '.Peer[] | select(.HostName=="skitarii") | {TailscaleIPs, KeyExpiry}'
ssh-keygen -R skitarii
ssh -o HostName=skitarii skitarii.friloux.me true
```

## Step 8 — Seal Public SSH

Revert `network.nix` to `services.openssh.openFirewall = false;`, then
deploy through the tailnet and check that port 22 no longer answers:

```bash
just install_skitarii
ssh skitarii.friloux.me true
nc -zv -w 5 5.196.4.180 22    # must time out
```

Bring pangolin's data back from Borg (sites, resources, users, TOTP,
license activation, gerbil's WireGuard key): extract the latest archive and
put the SQLite snapshots in place, as described in
[Rite of Restoration](restore.md). The Enterprise license is bound to the
server's host ID: if `/admin/license` shows it inactive after the restore,
re-enter it. crowdsec re-registers the bouncer by itself from sops.

Commit `.sops.yaml` and `secrets/skitarii.yaml`, then delete the local
copy of the host key:

```bash
rm -r /tmp/skitarii-extra
```

## Troubleshooting

### `Connection reset by peer` right after a failed login

sshd banned the source address for one hour (`PerSourcePenalties =
authfail:3600s`). With no KVM console, reboot the VPS from the OVH manager:
the ban lives in sshd's memory. Then connect with the right key only
(`IdentitiesOnly`).

### `sudo` refuses the password

Check what sops holds — a valid yescrypt hash starts with `$y$j9T$`:

```bash
sops -d --extract '["users"]["guillaume"]["hashed-password"]' secrets/skitarii.yaml | head -c 10; echo
```

A copy-paste can lose the prefix. Write the hash without the clipboard:

```bash
sops set secrets/skitarii.yaml '["users"]["guillaume"]["hashed-password"]' "$(mkpasswd -m yescrypt | jq -R .)"
```

Root cannot log in over SSH and `guillaume` cannot `sudo`, so a deploy
cannot fix it: redo the rite from step 3, keeping the same `/tmp/skitarii-extra`.

### `skitarii.friloux.me` does not resolve after creating the record

Asking for a name before it exists caches the `NXDOMAIN` for the SOA
minimum — 3 hours at Gandi — at every resolver on the way (Tailscale's
`100.100.100.100`, the home box). Check against `@1.1.1.1`; meanwhile use
`-o HostName=…`.

### Home Manager fails: `config.fish would be clobbered`

fish wrote an empty `~/.config/fish/config.fish` at the first login before
the home existed. Remove it and restart `home-manager-guillaume.service`.
