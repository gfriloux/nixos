---
title: Diagnosis & Recovery — Troubleshooting
description: Common issues and diagnostic procedures for the Forge.
---

Common problems and diagnostic rites.

## A Daemon Is Unhealthy

```bash
# View latest health check results
docker inspect --format='{{json .State.Health}}' <name> | jq

# View daemon logs
docker logs <name> --tail 50

# Manual restart
systemctl restart docker-<name>
```

The timer `docker-health-watch@<name>` automatically kills an `unhealthy` daemon
every 30 seconds, triggering a systemd restart.
If the daemon loops, inspect its logs.

## A systemd Service Is Failed

```bash
# View status and logs
systemctl status docker-<name>
journalctl -u docker-<name> --since "30 minutes ago"

# Reset failure counter before restarting
systemctl reset-failed docker-<name>
systemctl start docker-<name>
```

## Traefik Is Unresponsive

```bash
# Internal health check
docker exec traefik traefik healthcheck

# Verify container is running
docker ps | grep traefik

# Check Let's Encrypt certificates
ls -lh /srv/docker/traefik/acme.json
# If 0 bytes: certs not generated
# Let's Encrypt limit: 5 attempts/domain/hour

# Traefik logs
tail -100 /srv/docker/traefik/logs/traefik.log | jq .
```

## sops Cannot Decrypt Secrets

```bash
# Verify age key is present
ls -la /etc/sops/age/keys.txt

# Verify public key
age-keygen -y /etc/sops/age/keys.txt
# Should match the key in .sops.yaml

# Test decryption
sops -d secrets/clochette.yaml
```

If the public key does not match, see [Reliquary Backup & Restoration](secrets-backup.md).

## nixos-rebuild Deployment Fails

```bash
# Build without deploying to see the error
just build_clochette

# Verify linters
just test

# Verify flake evaluation
nix flake check
```

If it is a network error (download timeout), retry.
If it is a Nix eval error, read the full error message:
sops or missing type errors are usually explicit.

## SSH to clochette Is Unreachable

Verification order:

1. Is Tailscale active on both shrines?

   ```bash
   tailscale status  # from exampleHost
   ```

2. Is clochette reachable via Tailscale ping?

   ```bash
   tailscale ping clochette
   ```

3. Is the SSH daemon running on clochette?
   Use Scaleway serial console:

   ```bash
   systemctl status sshd
   ```

4. Is the firewall rule in place?

   ```bash
   sudo nft list ruleset | grep 100.64
   ```

## Docker Storage Driver ZFS (exampleHost)

If Docker fails to start on exampleHost with a ZFS error:

```bash
# Verify Docker dataset exists
zfs list | grep docker

# Docker uses rpool/nixos/var/lib as base
# Dataset is in /var/lib/docker
docker info | grep "Storage Driver"

# If Docker left a corrupted state
sudo systemctl stop docker
sudo rm -rf /var/lib/docker/devicemapper  # or problematic subdirectory
sudo systemctl start docker
```

## Borg Backup Fails

```bash
# Latest status
journalctl -u borgbackup-job-remote --since today

# Test SSH connection to backup server
ssh -i /run/secrets/services/borg/key/private backup@storage2.friloux.me

# Test repo access
BORG_PASSPHRASE=$(cat /run/secrets/services/borg/passphrase) \
BORG_RSH="ssh -i /run/secrets/services/borg/key/private" \
borg info ssh://backup@storage2.friloux.me/~/clochette.friloux.me
```

Common causes:

- Backup server SSH host key changed → update `backup.nix` `knownHostsFiles`
- Backup server disk full
- Borg lock held: `borg break-lock ssh://backup@storage2.friloux.me/~/clochette.friloux.me`

## ZFS Pool Degraded (exampleHost)

```bash
# Pool status
zpool status

# If a disk is DEGRADED/FAULTED
zpool status -v  # show errors

# After physically replacing a disk
zpool replace rpool /dev/disk/by-id/OLD_ID /dev/disk/by-id/NEW_ID
# Track resilver progress
zpool status -w rpool
```

## WeeCHAT / zellij Session Lost

```bash
# Connect to existing weechat session
ssh irc.friloux.me
# In the weechat shell:
zellij attach
```

If the zellij session no longer exists:

```bash
zellij  # creates new session
# Then restart weechat manually
weechat
```
