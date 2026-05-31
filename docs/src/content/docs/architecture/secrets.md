---
title: The Reliquary — Secrets & Encryption
description: sops-nix, age key management, storage locations, and access patterns.
---

Secrets are sealed with [sops](https://github.com/getsops/sops) and [age](https://age-encryption.org/) keys via the NixOS [sops-nix](https://github.com/Mic92/sops-nix) pattern. Treat the reliquary with reverence — guard its keys with extreme care.

## The Key Model

Each shrine bears its own age key (private/public pair).
The private age key of exampleHost is the **master key** — it unseals all reliquaries across the Forge.

| Shrine | Key Type | Private Location |
|---|---|---|
| exampleHost | Dedicated age file | `/etc/sops/age/keys.txt` |
| clochette | Derived from SSH host key | Derived at runtime from `/etc/ssh/ssh_host_ed25519_key` |
| RogueLeader | Derived from SSH host key | Derived at runtime from `/etc/ssh/ssh_host_ed25519_key` |

## Sealed Vaults

| File | Unsealable by |
|---|---|
| `secrets/kuri_exampleHost.yaml` | exampleHost only |
| `secrets/clochette.yaml` | clochette + exampleHost |
| `secrets/RogueLeader.yaml` | RogueLeader + exampleHost |

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
This reliquary is sealed for a reason. Mishandle the master key, and all shrines are exposed.
:::
