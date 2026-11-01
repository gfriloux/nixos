---
title: "Troubleshooting"
description: Containers, public web, sops, deploy, SSH, Borg, ZFS, weechat.
---

## Containers

One unit per container, named after the container (`immich-server`,
`papra`…), except newt: `docker-newt`.

```bash
docker inspect --format='{{json .State.Health}}' <name> | jq   # last healthchecks
docker logs <name> --tail 50
systemctl reset-failed <unit> && systemctl start <unit>
```

`stc-docker-health-watch@<name>` looks every 30 s and kills an `unhealthy`
container: systemd restarts it. If the restarts fail, the unit goes `failed`
and ntfy warns.

## A public site stops answering

Everything goes through skitarii: the machine's newt, then the gateway.

```bash
docker logs newt --tail 50                                   # clochette or RogueLeader
sudo docker logs traefik --tail 100                          # skitarii
sudo docker exec crowdsec cscli decisions list --ip <IP>     # skitarii, IP banned?
```

Next: [The gateway](/nixos/skitarii/gateway/).

## sops cannot decrypt

The machine's key must match `.sops.yaml`:

```bash
sudo nix shell nixpkgs#age -c age-keygen -y /etc/sops/age/keys.txt                    # exampleHost
nix shell nixpkgs#ssh-to-age -c ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub        # servers
```

Different: [Lost key](/nixos/operations/secrets-backup/#lost-key).

## The deploy fails

```bash
just build_clochette    # build without deploying (build, build_rogueleader, build_skitarii)
just test               # pre-commit on the whole repo
```

Network error: retry. Evaluation error: read the whole message.

## No SSH

clochette and skitarii: [Tailscale](/nixos/operations/tailscale/#without-ssh).
`Connection reset by peer` after a failed login: one-hour ban
(`PerSourcePenalties`), see [skitarii](/nixos/operations/reinstall-skitarii/#troubleshooting).

## Borg fails

```bash
journalctl -u borgbackup-job-remote --since today
sudo BORG_PASSPHRASE=$(sudo cat /run/secrets/services/borg/passphrase) \
  BORG_RSH="ssh -i /run/secrets/services/borg/key/private" \
  borg info ssh://backup@storage2.friloux.me/~/clochette.friloux.me
```

| Cause | Fix |
|---|---|
| storage2's host key changed | `knownHostsFiles` in `backup.nix` |
| storage2 full | on storage2 |
| Stale lock | `borg break-lock <repo>` |

## Degraded ZFS pool (exampleHost)

```bash
zpool status -v
```

New disk: copy the other's table (`sgdisk -R <new> <remaining>`, then
`sgdisk -G <new>`), `zpool replace` on **bpool and rpool**, put its ID in
`disko.nix` **and** `boot.nix`, then `just install` (GRUB on both disks).
Follow: `zpool status -w rpool`.

## Lost weechat session

```bash
ssh irc.friloux.me
zellij attach      # or `zellij` then `weechat` if the session is gone
```
