---
title: The Reliquary & sops-nix — Daily Secret Management
description: Unsealing and rotating secrets, declaring new secrets, adding machines to the keychain.
---

Reference for daily secret management with sops-nix.

For backup and restoration procedures, see [Reliquary Backup & Restoration](secrets-backup.md).

## Unsealing a Secret File

```bash
# Open in $EDITOR (decrypt → edit → re-encrypt at close)
sops secrets/clochette.yaml
sops secrets/kuri_exampleHost.yaml
sops secrets/RogueLeader.yaml

# Shortcuts via just
just secrets            # kuri_exampleHost.yaml
just secrets_clochette  # clochette.yaml
just secrets_rogueleader  # RogueLeader.yaml
```

## Reading a Secret Without Editing

```bash
# Decrypt and display plaintext
sops -d secrets/clochette.yaml

# Extract a single value (nested YAML format with .)
sops -d --extract '["services"]["ntfy"]["topic"]' secrets/clochette.yaml
```

## Adding a New Secret

1. Unseal the file with `sops secrets/clochette.yaml`
2. Add the key/value plaintext — sops encrypts it at save
3. Declare the secret in the NixOS config of the target shrine:

```nix
# In docker-*.nix or default.nix
sops.secrets."services/myservice/env" = {};
```

4. Reference in the container config:

```nix
virtualisation.oci-containers.containers."myservice" = {
  environmentFiles = [
    config.sops.secrets."services/myservice/env".path
  ];
};
```

:::note[Marginalia]
Declare secrets near the service that uses them (in `docker-*.nix`), not in `default.nix`.
:::

## Decrypted Secret Locations at Runtime

When the shrine awakens, secrets are deposited in:

| Shrine | Location | Usage |
|---|---|---|
| clochette | `/run/secrets/<name>` | System secrets (containers, users) |
| exampleHost | `/run/secrets/<name>` | System secrets |
| exampleHost (HM) | `/run/user/1000/secrets/<name>` | Home Manager secrets (kuri) |

Reference a secret in systemd or shell:

```bash
cat /run/secrets/services/ntfy/topic
```

In NixOS config, always use `config.sops.secrets."<name>".path`
to get the path — never hardcode `/run/secrets/...`.

## Secret File Structure

```yaml
# secrets/clochette.yaml (structure when decrypted)
users:
    guillaume:
        hashed-password: "..."
services:
    ntfy:
        topic: "..."
    traefik:
        conf:
            traefik_dynamic.yml: "..."
    crowdsec:
        env: "..."
    papra:
        env: "..."
    wow-cp:
        env_bookstack: "..."
        env_mariadb: "..."
        env_mysqldump: "..."
    immich:
        env: "..."
    borg:
        passphrase: "..."
        key:
            private: "..."
```

## Rotating a Secret

To change an existing secret's value:

```bash
sops secrets/clochette.yaml
# Modify the value, save
```

Then redeploy so sops-nix deposits the new value in `/run/secrets`:

```bash
just install_clochette --ask-sudo-password
```

Containers reading via `environmentFiles` restart automatically
after redeployment thanks to systemd.

## Adding a Machine to Encryption Rules

When a new shrine is added to the flake, grant it the ability to unseal its secrets:

1. Obtain its public age key:
   - If dedicated age file: `age-keygen -y /etc/sops/age/keys.txt`
   - If derived from SSH: `ssh-to-age -i /etc/ssh/ssh_host_ed25519_key.pub`

2. Add to `.sops.yaml`:

```yaml
keys:
  - &new_shrine age1XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
creation_rules:
  - path_regex: secrets/new_shrine.yaml$
    key_groups:
    - age:
      - *new_shrine
      - *desktop_examplehost  # always include exampleHost for editing
```

3. Create the secret file:

```bash
sops secrets/new_shrine.yaml
```
