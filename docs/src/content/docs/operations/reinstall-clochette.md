---
title: "Reinstall clochette"
description: From the Dedibox rescue to the first deploy, with nixos-anywhere from exampleHost.
---

:::danger
Step 5 wipes clochette's disk. Immich is down until the Borg restore
(step 9).
:::

| | |
|---|---|
| IP | `51.159.34.135`, gateway `51.159.34.1` |
| Disk | `/dev/sda`, BIOS, GPT + EF02 (`disko.nix`) |
| Console | Dedibox serial, kernel on `ttyS1` |
| sops | age key derived from `/etc/ssh/ssh_host_ed25519_key` |
| SSH | Tailscale only (`100.64.0.0/10`) |

## Before

- Access to the Dedibox console (rescue mode, serial console).
- The YubiKey (`sops`) and the Tailscale admin console.
- A recent Borg archive: [Restore from Borg](/nixos/operations/restore/).

## 1. Switch to disko (permanent)

`disko.nix` exists but is not imported: the current install is MBR, with no
partlabels. Done once, at the first reinstall.

In `systems/x86_64-linux/clochette/default.nix`:

```nix
imports = [
  inputs.disko.nixosModules.disko
  ./disko.nix
  # …
];

boot.loader.grub.enable = true;   # replaces the block with device = "/dev/sda": disko provides it
```

In `hardware-configuration.nix`, delete `fileSystems."/"`,
`fileSystems."/boot"` and `swapDevices`. Check:

```bash
nix eval '.#nixosConfigurations.clochette.config.fileSystems."/".device'   # /dev/disk/by-partlabel/disk-main-root
```

Then remove the "Pas encore importé" comment from `disko.nix`.

## 2. Open public SSH (temporary)

The new machine is not on the tailnet. In `default.nix`:

```nix
openFirewall = true; # TEMPORARY: not on the tailnet yet
```

Do not commit.

## 3. Generate the host key

```bash
mkdir -p /tmp/clochette-extra/etc/ssh
ssh-keygen -q -t ed25519 -N "" -C root@clochette -f /tmp/clochette-extra/etc/ssh/ssh_host_ed25519_key
nix shell nixpkgs#ssh-to-age -c ssh-to-age < /tmp/clochette-extra/etc/ssh/ssh_host_ed25519_key.pub
ssh-keygen -lf /tmp/clochette-extra/etc/ssh/ssh_host_ed25519_key.pub   # fingerprint to check at step 6
```

Put the age key in `&server_clochette` (`.sops.yaml`), then:

```bash
sops updatekeys secrets/clochette.yaml   # YubiKey
```

## 4. Boot the rescue

Dedibox console → clochette → **Rescue**. The login and password show on
the server page. The rescue opens a regular user; nixos-anywhere wants root.

```bash
ssh-keygen -R 51.159.34.135
ssh-copy-id -o PubkeyAuthentication=no -i ~/.ssh/id_ed25519 <login>@51.159.34.135
ssh <login>@51.159.34.135 'sudo mkdir -p /root/.ssh && sudo cp ~/.ssh/authorized_keys /root/.ssh/ && lsblk'
ssh root@51.159.34.135 true
```

If root is refused, give `<login>` passwordless sudo and target `<login>@`
at step 5:

```bash
ssh -t <login>@51.159.34.135 'echo "<login> ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/anywhere'
```

If the disk is not `sda` in rescue, put its name in `disko.nix` for the
install, then go back to `/dev/sda` (as for
[skitarii](/nixos/operations/reinstall-skitarii/)).

## 5. Install

```bash
ssh-add ~/.ssh/id_ed25519
nix run github:nix-community/nixos-anywhere -- \
  --flake .#clochette \
  --target-host root@51.159.34.135 \
  --ssh-option IdentitiesOnly=yes \
  --ssh-option IdentityFile=$HOME/.ssh/id_ed25519.pub \
  --phases kexec,disko,install \
  --extra-files /tmp/clochette-extra
```

No `reboot` phase: the machine would come back in rescue. After `Shared
connection closed`, wait, nixos-anywhere resumes on its own. Expected:

```text
sops-install-secrets: Imported /etc/ssh/ssh_host_ed25519_key as age key with fingerprint age1…
installing the GRUB 2 boot loader on /dev/sda...
### Done! ###
```

The age fingerprint must match `.sops.yaml`.

## 6. First boot

Dedibox console → leave rescue, reboot. The serial console shows
`clochette login:`. Then:

```bash
ssh-keygen -R 51.159.34.135
ssh -t -o HostName=51.159.34.135 -o IdentitiesOnly=yes clochette.friloux.me sudo true
```

Accept only the fingerprint noted at step 3.

## 7. Tailscale

Tailscale admin console: **delete the old clochette entry** first, otherwise
the node becomes `clochette-1` and the ssh block points at a dead name.

```bash
sudo tailscale up            # on clochette, open the URL
```

Then **⋯ → Disable key expiry**. From exampleHost:

```bash
ssh-keygen -R clochette
ssh clochette.friloux.me true
```

## 8. Close public SSH

Set `openFirewall = false;` back in `default.nix`, then:

```bash
just install_clochette
nc -zv -w 5 51.159.34.135 22    # must time out
```

Commit the disko switch, `.sops.yaml` and `secrets/clochette.yaml`, then
`rm -r /tmp/clochette-extra`.

## 9. Restore

From Borg: `/srv/docker/photos.friloux.me` and `/home/weechat/.config/weechat`.
The Immich database is reloaded from its dump, otherwise it starts empty:
[Immich (clochette)](/nixos/operations/restore/#immich-clochette).

## 10. Check

```bash
docker ps --format "table {{.Names}}\t{{.Status}}"   # newt, immich-* healthy
docker logs newt --tail 20                           # tunnel to skitarii
systemctl start borgbackup-job-remote && systemctl status borgbackup-job-remote
```

`https://photos.friloux.me` answers, and `irc.friloux.me` opens the weechat session.

## Troubleshooting

| Symptom | Cause, fix |
|---|---|
| `Connection reset by peer` after a failed login | One-hour ban (`PerSourcePenalties`). Reboot from the Dedibox console, retry with `IdentitiesOnly=yes`. |
| `sudo` refuses the password | Broken hash in sops, see [skitarii](/nixos/operations/reinstall-skitarii/#sudo-refuses-the-password). |
| No SSH at all | Dedibox serial console, login `guillaume`. |
