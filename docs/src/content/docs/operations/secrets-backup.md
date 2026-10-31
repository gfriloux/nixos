---
title: Reliquary Backup & Restoration — Age Key Management
description: Who holds which key, how to edit secrets with the YubiKey, and how to recover from a lost key or a reinstall.
---

Secrets are sealed with [sops-nix](https://github.com/Mic92/sops-nix) and [age](https://age-encryption.org/) keys.
The encrypted files (`.yaml`) are versioned in git — safe to expose without the private keys.
What must be guarded is the **rescue key**, the only key that is not tied to a device.

## Key Custody

| Key | Role | Where the private part lives | Opens |
|---|---|---|---|
| exampleHost | Boot of exampleHost | `/etc/sops/age/keys.txt` (clear, `0640 root:users`) | `kuri_exampleHost.yaml` |
| clochette | Boot of clochette | derived from `/etc/ssh/ssh_host_ed25519_key` | `clochette.yaml` |
| RogueLeader | Boot of RogueLeader | derived from `/etc/ssh/ssh_host_ed25519_key` | `RogueLeader.yaml` |
| skitarii | Boot of skitarii | derived from `/etc/ssh/ssh_host_ed25519_key` | `skitarii.yaml` |
| YubiKey | Editing with `sops` | YubiKey 5 NFC (serial 36644572), PIV slot 1 | all four |
| Rescue | Editing if the YubiKey is lost | offline, off every shrine | all four |

Public keys and recipients per file are in `.sops.yaml`.

A host key opens its own file only. Reading exampleHost's disk exposes
exampleHost's secrets — which include SSH keys to the servers — but not the
servers' sops files. **Never add a host key as a recipient of another shrine's
file**: that would bring back a single key that opens everything.

## Editing Secrets with the YubiKey

`sops` finds the YubiKey through an identity stub, which holds no secret
(serial, slot, and a public tag). It lives in `~/.config/sops/age/keys.txt`:

```text
#       Serial: 36644572, Slot: 1
#         Name: sops-master
#    Recipient: age1yubikey1qtsqgx98tq7d005aue4lqth3z5hgu67e9eee490mpf0phfx7znghqr8x67l
AGE-PLUGIN-YUBIKEY-1MSNZ7Q5ZKGQ5JCG67Q42J
```

`sops` needs `age-plugin-yubikey` in `PATH`, even to encrypt. STC's
`relics-yubikey-user` installs it:

```bash
sops secrets/clochette.yaml
```

- **PIN**: the PIV PIN, 6 to 8 characters. It is not the GPG (OpenPGP) PIN.
  A longer PIN fails with `size error` before the YubiKey even checks it.
  Asked once per session.
- **Touch**: required for every decryption.
- **`Failed to decrypt YubiKey stanza`**: the key was not touched in time
  (about 15 seconds). Run the command again.
- GnuPG and PIV share the card through pcscd
  ([gfriloux/stc#111](https://github.com/gfriloux/stc/issues/111)): no need to
  stop `scdaemon` first.

## The Rescue Key

A plain age key, generated on 2026-10-25, stored offline and on no shrine.
Its public key is `age1faz4m9gj9xyz4rm26gndwgjkwrwr9ppnzm48slcrne7uvf3afqcsxtv8hs`.

To use it, put it in a temporary file, point sops at it, then destroy the file:

```bash
SOPS_AGE_KEY_FILE=/tmp/rescue.txt sops secrets/clochette.yaml
shred -u /tmp/rescue.txt
```

## Verification Procedure

Run a few times a year. The output goes to `/dev/null`: no secret is shown.

```bash
# YubiKey: opens every file (PIN, then touch for each)
for f in kuri_exampleHost clochette RogueLeader; do
  SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt \
    sops -d secrets/$f.yaml > /dev/null && echo "$f OK"
done

# exampleHost's boot key: opens its own file, and only that one
for f in kuri_exampleHost clochette RogueLeader; do
  SOPS_AGE_KEY_FILE=/etc/sops/age/keys.txt sops -d secrets/$f.yaml > /dev/null 2>&1 \
    && echo "$f: opens" || echo "$f: refused"
done
# Expected: kuri_exampleHost opens, clochette and RogueLeader refused
```

Test the rescue key the same way from its offline copy.

## Reinstalling exampleHost

The boot key is no longer precious: a reinstall gets a new one.

1. Generate it:

   ```bash
   sudo mkdir -p /etc/sops/age
   sudo age-keygen -o /etc/sops/age/keys.txt
   sudo chown root:users /etc/sops/age/keys.txt && sudo chmod 640 /etc/sops/age/keys.txt
   sudo age-keygen -y /etc/sops/age/keys.txt    # new public key
   ```

2. In `.sops.yaml`, replace `&desktop_examplehost` with the new public key.
3. Re-encrypt exampleHost's file with the YubiKey:

   ```bash
   sops updatekeys secrets/kuri_exampleHost.yaml
   ```

4. Commit `.sops.yaml` and the file, then deploy: `just install`.

The old `keys.txt`, if a backup of it still exists, no longer opens anything
once `updatekeys` has run: destroy it.

## Reinstalling clochette or RogueLeader

A reinstall generates a **new SSH host key**, so the derived age key changes.

1. Get the new public key, from the reinstalled shrine:

   ```bash
   nix run nixpkgs#ssh-to-age -- -i /etc/ssh/ssh_host_ed25519_key.pub
   ```

2. In `.sops.yaml`, replace `&server_clochette` (or `&server_rogueleader`).
3. Re-encrypt, from exampleHost, with the YubiKey:

   ```bash
   sops updatekeys secrets/clochette.yaml
   ```

4. Commit, then deploy: `just install_clochette` (or `just install_rogueleader`).

## Lost Keys

| Lost | Consequence | Recovery |
|---|---|---|
| exampleHost's boot key | exampleHost cannot decrypt its secrets at boot | Reinstall procedure above, with the YubiKey |
| A server's SSH host key | That server cannot decrypt its secrets | Server reinstall procedure above |
| YubiKey | No more editing with it | Use the rescue key, enrol a new YubiKey, `updatekeys` all four files, remove the old `&admin_yubikey` |
| Rescue key | No fallback if the YubiKey is lost | Generate a new one, `updatekeys` all four files with the YubiKey |
| YubiKey **and** rescue key | No admin key left | Each file can still be read on its own shrine with its host key: re-encrypt from there to new admin keys |

:::danger[Interdict]
Losing the YubiKey and the rescue key together leaves no key that opens every file.
Keep the rescue key offline, away from the YubiKey, and test it.
:::
