---
title: "Compromised age key"
description: A key someone else may hold. Replace it, re-key the files, change every secret it could read.
---

A lost key is replaced: [Age key backup](/nixos/operations/secrets-backup/#lost-key).
A key someone else may hold is another matter. The repository is public: every
past version of the sops files stays readable with that key, whatever is done
afterwards. Replacing the key is not enough, **every secret it could open must
change**.

## Scope

| Key in doubt | Files it opens |
|---|---|
| YubiKey or rescue key | all four |
| exampleHost boot key | `secrets/kuri_exampleHost.yaml` |
| A server's host key | that server's file |

```bash
grep -c 'ENC\[' secrets/*.yaml    # values per file: 65 in all on 2026-11-18
```

- **Rescue key**: a plain file, copied without a trace.
- **YubiKey**: the key cannot be extracted. In doubt only if someone held the
  token and knew the PIV PIN.
- **Host key**: whoever read it was root on that machine. Treat the machine as
  compromised too, not only its file.

## 1. Replace the key

Rescue key, then the public key goes in `&admin_rescue` (`.sops.yaml`):

```bash
age-keygen -o /tmp/rescue-new.txt    # prints the public key
```

YubiKey, then the recipient goes in `&admin_yubikey`:

```bash
age-plugin-yubikey --generate --slot 1 --name sops-master --force
age-plugin-yubikey --identity --slot 1 > ~/.config/sops/age/keys.txt
```

`--force` destroys the old identity: from then on only the rescue key opens
the files, so check it first ([Check](/nixos/operations/secrets-backup/#check)).

Boot key or host key: same fix as a
[lost key](/nixos/operations/secrets-backup/#lost-key), then steps 2 to 4 on
that file only.

## 2. Re-key the files

With the admin key that is not in doubt:

```bash
sops updatekeys -y secrets/*.yaml
sops rotate -i secrets/kuri_exampleHost.yaml
sops rotate -i secrets/clochette.yaml
sops rotate -i secrets/RogueLeader.yaml
sops rotate -i secrets/skitarii.yaml
```

`updatekeys` swaps the recipients and keeps the data key. `rotate` draws a new
one: without it, a data key already extracted still opens the file.

## 3. Change every secret

The key names are in clear in the files. New value at the source, then
`sops secrets/<file>.yaml`.

| Secret | New value from |
|---|---|
| `users/*/hashed-password` | `mkpasswd` |
| SSH keys (`ssh/keys/*`, `borg/key/*`, `borg-ui/ssh-key`) | `ssh-keygen`, public part replaced on the far end (GitHub, servers, storage2) |
| `borg/passphrase` | `borg key change-passphrase`; past archives are not re-encrypted |
| `tokens/*`, `mail/password` | the provider |
| `newt/*`, `pangolin/secret`, `crowdsec/*` | pangolin dashboard, `cscli` |
| Service env files (`immich`, `papra`, `wow-cp`) | each application: database password, app key |
| `ntfy/topic`, `kuma/*` | a new topic, a new push monitor |

## 4. Deploy and check

Commit, then `just install` and each `just install_<machine>`. Restart the
containers: no secret has `restartUnits`.

```bash
# The old key must be refused
SOPS_AGE_KEY_FILE=/tmp/old-key.txt sops -d secrets/skitarii.yaml > /dev/null
```

Then the two loops of [Check](/nixos/operations/secrets-backup/#check).

## Tested

2026-11-18, step 2 and the refusal, with throwaway keys on dummy files:

- after `updatekeys`, the old key is refused but the ciphertext is unchanged;
- after `rotate`, the ciphertext changes;
- the old key still opens the earlier version of the file.

Never run: the YubiKey commands of step 1, and step 3 on the real files.
