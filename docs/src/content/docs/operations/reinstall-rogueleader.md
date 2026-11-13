---
title: "Reinstall RogueLeader"
description: From the NixOS ISO to the first deploy, with nixos-anywhere from exampleHost.
---

:::danger
Step 4 wipes RogueLeader's disk. The services its newt publishes are down
until the Borg restore (step 7).
:::

| | |
|---|---|
| Network | DHCP, `192.168.0.10` (`rogueleader.home`) |
| Disk | `/dev/sda`, BIOS, GPT + EF02 (`disko.nix`) |
| sops | age key derived from `/etc/ssh/ssh_host_ed25519_key` |
| SSH | LAN, `guillaume`, key `root@rogueleader` |

## Before

- Physical access (screen, keyboard), a USB stick with the minimal NixOS ISO.
- The YubiKey (`sops`).
- A recent Borg archive: [Restore from Borg](/nixos/operations/restore/).

## 1. Generate the host key

Without it, the new machine cannot read its sops file: no password, no sudo,
no deploy possible.

```bash
mkdir -p /tmp/rogueleader-extra/etc/ssh
ssh-keygen -q -t ed25519 -N "" -C root@RogueLeader -f /tmp/rogueleader-extra/etc/ssh/ssh_host_ed25519_key
nix shell nixpkgs#ssh-to-age -c ssh-to-age < /tmp/rogueleader-extra/etc/ssh/ssh_host_ed25519_key.pub
ssh-keygen -lf /tmp/rogueleader-extra/etc/ssh/ssh_host_ed25519_key.pub   # fingerprint to check at step 5
```

Put the age key in `&server_rogueleader` (`.sops.yaml`), then:

```bash
sops updatekeys secrets/RogueLeader.yaml   # YubiKey
```

## 2. Boot the ISO

On RogueLeader's console:

```bash
passwd                # throwaway password for the nixos user
ip -4 addr            # the ISO's IP
lsblk                 # the internal disk, not the USB stick
```

If the internal disk is not `sda` (the USB stick took it), put its name in
`disko.nix` for the install, then go back to `/dev/sda` (as for
[skitarii](/nixos/operations/reinstall-skitarii/)).

## 3. Copy the key

```bash
ssh-copy-id -o PubkeyAuthentication=no -i ~/.ssh/id_ed25519 nixos@<iso-ip>
```

## 4. Install

The ISO is already NixOS: no `kexec` phase. The `nixos` user has
passwordless sudo.

```bash
ssh-add ~/.ssh/id_ed25519
nix run github:nix-community/nixos-anywhere -- \
  --flake .#RogueLeader \
  --target-host nixos@<iso-ip> \
  --ssh-option IdentitiesOnly=yes \
  --ssh-option IdentityFile=$HOME/.ssh/id_ed25519.pub \
  --phases disko,install \
  --extra-files /tmp/rogueleader-extra
```

Expected: `Imported /etc/ssh/ssh_host_ed25519_key as age key`, then
`### Done! ###`. The age fingerprint must match `.sops.yaml`.

## 5. First boot

Remove the USB stick, reboot. Then:

```bash
ssh-keygen -R 192.168.0.10
ssh -t rogueleader.home sudo true
```

Accept only the fingerprint noted at step 1.

## 6. Deploy

```bash
just install_rogueleader
just home_rogueleader
```

Commit `.sops.yaml` and `secrets/RogueLeader.yaml`, then
`rm -r /tmp/rogueleader-extra`.

## 7. Restore

The archives hold no live database:

- BookStack: reload the MariaDB dump,
  [BookStack (RogueLeader)](/nixos/operations/restore/#bookstack-rogueleader).
- Uptime Kuma, Papra, Mealie, borg-ui: put the `sqlite-snapshots/` copies back,
  [SQLite services (RogueLeader)](/nixos/operations/restore/#sqlite-services-rogueleader).

## 8. Check

```bash
docker ps --format "table {{.Names}}\t{{.Status}}"   # all healthy
docker logs newt --tail 20                           # tunnel to skitarii
systemctl start borgbackup-job-remote && systemctl status borgbackup-job-remote
```

`https://status.friloux.me`, `wow-cp`, `docs`, `cuisine` and `borg-ui`
answer.
