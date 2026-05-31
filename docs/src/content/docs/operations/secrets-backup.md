---
title: Reliquary Backup & Restoration — Age Key Management
description: Safeguarding the master key, recovering from loss, updating keys after reinstall.
---

Secrets are sealed with [sops-nix](https://github.com/Mic92/sops-nix) and [age](https://age-encryption.org/) keys.
The encrypted files (`.yaml`) are versioned in git — safe to expose without the private key.
What must be **absolutely** guarded is the master age key of exampleHost.

## Secret Files Overview

| File | Encrypted by |
|---|---|
| `secrets/kuri_exampleHost.yaml` | exampleHost age key only |
| `secrets/clochette.yaml` | clochette age key **+** exampleHost age key |
| `secrets/RogueLeader.yaml` | RogueLeader age key **+** exampleHost age key |

**Critical**: The private age key of exampleHost unseals **all** reliquaries across the Forge.
Loss of this key renders `kuri_exampleHost.yaml` irrecoverable.

## Age Keys by Shrine

### exampleHost

- **Type**: Dedicated age key, manually managed
- **Location**: `/etc/sops/age/keys.txt`
- **Permissions**: `0640 root:users` (readable by `users` group)
- **Public key**: `age1xr32hdvanup0zk63v8hrcv2u2c09wplz6fd42w47mkjrd49j39xqaqqckq`

This is the **only key that must be backed up offline**. See procedure below.

### clochette

- **Type**: Age key derived from SSH host ed25519 key
- **Source**: `/etc/ssh/ssh_host_ed25519_key` (auto-generated at install)
- **Public key**: `age18594hnd4mk3736a36a5fqc5w55sanac86tv8du0hz67rfk558srs3y9jwa`

The age private key does not exist as a file — sops-nix derives it on-the-fly from the SSH host key.
After reinstall, a new SSH host key is generated → age key changes → update `.sops.yaml`.

### RogueLeader

- **Type**: Age key derived from SSH host ed25519 key
- **Source**: `/etc/ssh/ssh_host_ed25519_key` (explicit in config)
- **Public key**: `age1nttxr633hf6r43szc9ffl2a0avmtmhtl7hhnjjuyd3sc4au705nqffyfwe`

Same behaviour as clochette.

## What Is Already Backed Up

| Element | Where | Status |
|---|---|---|
| Encrypted secret files (`*.yaml`) | git repo | ✅ Auto-versioned |
| sops config (`.sops.yaml`) | git repo | ✅ Auto-versioned |
| exampleHost age private key | `/etc/sops/age/keys.txt` | ⚠️ Manual backup required |
| clochette/RogueLeader SSH host keys | `/etc/ssh/ssh_host_ed25519_key` | ⚠️ Regenerated at each reinstall |

## Backup Procedure — exampleHost Age Key

### Display Public Key (Verification)

From exampleHost:

```bash
age-keygen -y /etc/sops/age/keys.txt
```

Expected output:

```
age1xr32hdvanup0zk63v8hrcv2u2c09wplz6fd42w47mkjrd49j39xqaqqckq
```

If this does not match the key in `.sops.yaml`, investigate immediately.

### Display Private Key

```bash
sudo cat /etc/sops/age/keys.txt
```

Content looks like:

```
# created: 2024-01-01T00:00:00+01:00
# public key: age1xr32hdvanup0zk63v8hrcv2u2c09wplz6fd42w47mkjrd49j39xqaqqckq
AGE-SECRET-KEY-1XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

### Where to Store the Backup

Store the private key in **at least two** of the following:

1. **Password manager** (Bitwarden/rbw): paste full content in a secure note
2. **Encrypted USB** (LUKS) stored offsite
3. **Paper** in a safe place (safe deposit box, etc.) — plain text sufficient

Never store the backup only on exampleHost itself.

## Verification Procedure

Regularly verify the backup can decrypt secrets.

From exampleHost, with the key in place:

```bash
# Decrypt clochette.yaml (displays plaintext — do not share terminal)
sops -d secrets/clochette.yaml

# Decrypt kuri_exampleHost.yaml
sops -d secrets/kuri_exampleHost.yaml

# Decrypt RogueLeader.yaml
sops -d secrets/RogueLeader.yaml
```

These must execute without error. If sops returns `could not decrypt`, the key is missing or wrong.

## Restoration Procedure — exampleHost Age Key

Situation: exampleHost was reinstalled, `/etc/sops/age/keys.txt` no longer exists.

**1. Create the directory**

```bash
sudo mkdir -p /etc/sops/age
sudo chmod 750 /etc/sops/age
```

**2. Restore the key from backup**

Paste the complete backup content (full private key) into the file:

```bash
sudo micro /etc/sops/age/keys.txt
# or
sudo tee /etc/sops/age/keys.txt << 'EOF'
# created: 2024-01-01T00:00:00+01:00
# public key: age1xr32hdvanup0zk63v8hrcv2u2c09wplz6fd42w47mkjrd49j39xqaqqckq
AGE-SECRET-KEY-1XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
EOF
```

**3. Correct permissions**

```bash
sudo chmod 640 /etc/sops/age/keys.txt
sudo chown root:users /etc/sops/age/keys.txt
```

**4. Verify**

```bash
age-keygen -y /etc/sops/age/keys.txt
# Must display: age1xr32hdvanup0zk63v8hrcv2u2c09wplz6fd42w47mkjrd49j39xqaqqckq

sops -d secrets/kuri_exampleHost.yaml
# Must display decrypted content without error
```

**5. Redeploy NixOS**

```bash
just install_examplehost --ask-sudo-password
```

sops-nix re-deposits secrets in `/run/secrets` and `/run/user/1000/secrets`.

## Post-Reinstall Procedure — clochette or RogueLeader

When clochette or RogueLeader is reinstalled, a **new SSH host key** is generated.
The derived age key changes and no longer matches `.sops.yaml`.
Update `.sops.yaml` and re-encrypt the affected secrets.

### 1. Obtain the New Age Public Key

From the reinstalled shrine (via Tailscale or console):

```bash
# Convert SSH host key to age public key
nix run nixpkgs#ssh-to-age -- -i /etc/ssh/ssh_host_ed25519_key.pub
```

Example output:

```
age18594hnd4mk3736a36a5fqc5w55sanac86tv8du0hz67rfk558srs3y9jwa
```

### 2. Update `.sops.yaml`

In the git repo, replace the old public key with the new one.

For clochette, edit `.sops.yaml`:

```yaml
keys:
  - &server_clochette age1NEW_PUBLIC_KEY_HERE
```

For RogueLeader:

```yaml
keys:
  - &server_rogueleader age1NEW_PUBLIC_KEY_HERE
```

### 3. Re-encrypt Secret Files

From exampleHost (which can still decrypt via its master key):

```bash
# For clochette
sops updatekeys secrets/clochette.yaml

# For RogueLeader
sops updatekeys secrets/RogueLeader.yaml
```

`updatekeys` re-encrypts with the keys now defined in `.sops.yaml`.
Confirm with `y` when sops asks.

### 4. Verify and Commit

```bash
# Verify files are updated
git diff secrets/

# Commit
git add .sops.yaml secrets/clochette.yaml  # or secrets/RogueLeader.yaml
git commit -m "chore(secrets): rotate age key for clochette after reinstall"
```

### 5. Deploy

```bash
just install_clochette --ask-sudo-password
```

## Catastrophe Scenario — Lost Master Key Without Backup

If the exampleHost private age key is lost **and** no backup exists:

| File | Situation |
|---|---|
| `kuri_exampleHost.yaml` | **Irrecoverable** — encrypted only with lost key |
| `clochette.yaml` | Recoverable from clochette (via its SSH host key) |
| `RogueLeader.yaml` | Recoverable from RogueLeader (via its SSH host key) |

**For `kuri_exampleHost.yaml`: start from scratch**

```bash
# Generate a new age key
age-keygen -o /etc/sops/age/keys.txt

# Display the new public key
age-keygen -y /etc/sops/age/keys.txt

# Update .sops.yaml with the new public key
# Replace desktop_examplehost

# Recreate kuri_exampleHost.yaml from scratch
sops secrets/kuri_exampleHost.yaml
# Manually enter all secrets (passwords, etc.)

# Re-encrypt clochette.yaml and RogueLeader.yaml with new key
sops updatekeys secrets/clochette.yaml
sops updatekeys secrets/RogueLeader.yaml

# Commit
git add .sops.yaml secrets/
git commit -m "chore(secrets): rotate all age keys after exampleHost key loss"
```

:::danger[Interdict]
This scenario underscores the importance of offline backup of `/etc/sops/age/keys.txt`.
:::
