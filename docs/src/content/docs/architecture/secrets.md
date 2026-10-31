---
title: The Reliquary — Secrets & Encryption
description: sops-nix, age key management, storage locations, and access patterns.
---

Secrets are sealed with [sops](https://github.com/getsops/sops) and [age](https://age-encryption.org/) keys via the NixOS [sops-nix](https://github.com/Mic92/sops-nix) pattern. Treat the reliquary with reverence — guard its keys with extreme care.

## The Key Model

Two kinds of keys, with separate jobs:

- **Host keys** decrypt a shrine's own file at boot. Each one opens a single
  file, so a shrine whose disk is read exposes its own secrets, not the
  others'.
- **Admin keys** edit the files with `sops`. They are recipients of every
  file and never sit in clear on a shrine.

| Key | Kind | Private part | Opens |
|---|---|---|---|
| exampleHost | Host, dedicated age file | `/etc/sops/age/keys.txt` | `kuri_exampleHost.yaml` |
| clochette | Host, derived from SSH host key | `/etc/ssh/ssh_host_ed25519_key` | `clochette.yaml` |
| RogueLeader | Host, derived from SSH host key | `/etc/ssh/ssh_host_ed25519_key` | `RogueLeader.yaml` |
| skitarii | Host, derived from SSH host key | `/etc/ssh/ssh_host_ed25519_key` | `skitarii.yaml` |
| YubiKey | Admin, age identity in PIV slot 1 | on the YubiKey, not extractable | all four |
| Rescue | Admin, plain age key | offline, off every shrine | all four |

## Sealed Vaults

| File | Unsealable by |
|---|---|
| `secrets/kuri_exampleHost.yaml` | exampleHost + YubiKey + rescue |
| `secrets/clochette.yaml` | clochette + YubiKey + rescue |
| `secrets/RogueLeader.yaml` | RogueLeader + YubiKey + rescue |
| `secrets/skitarii.yaml` | skitarii + YubiKey + rescue |

## Unsealing at Boot

sops-nix deposits decrypted secrets in `/run/secrets/` when the shrine awakens.
Secrets marked `neededForUsers = true` are deposited in `/run/secrets-for-users/` before user creation (for hashed passwords).

On exampleHost, Home Manager places its secrets in `/run/user/1000/secrets/`.

## The Configuration (`.sops.yaml`)

```yaml
keys:
  - &desktop_examplehost age1xr32hdvanup0zk63v8hrcv2u2c09wplz6fd42w47mkjrd49j39xqaqqckq
  - &server_clochette     age18594hnd4mk3736a36a5fqc5w55sanac86tv8du0hz67rfk558srs3y9jwa
  - &server_rogueleader   age1nttxr633hf6r43szc9ffl2a0avmtmhtl7hhnjjuyd3sc4au705nqffyfwe
  - &admin_yubikey        age1yubikey1qtsqgx98tq7d005aue4lqth3z5hgu67e9eee490mpf0phfx7znghqr8x67l
  - &admin_rescue         age1faz4m9gj9xyz4rm26gndwgjkwrwr9ppnzm48slcrne7uvf3afqcsxtv8hs
```

Each file's sealing rules are defined under `creation_rules`.

## Declaring Secrets in NixOS

Always reference via `config.sops.secrets."<path>".path` — never hardcode `/run/secrets/...`:

```nix
sops.secrets."services/papra/env" = {};

environmentFiles = [
  config.sops.secrets."services/papra/env".path
];
```

For user passwords:

```nix
sops.secrets."users/kuri/hashed-password".neededForUsers = true;
users.users.kuri.hashedPasswordFile =
  config.sops.secrets."users/kuri/hashed-password".path;
```

:::caution[Ward]
This reliquary is sealed for a reason. Never make a host key a recipient of another shrine's file: that is how one stolen disk would expose every shrine.
:::
