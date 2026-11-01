---
title: "Secrets"
description: sops-nix and age, which key opens which file, editing, referencing a secret.
---

[sops-nix](https://github.com/Mic92/sops-nix), [age](https://age-encryption.org/) encryption.
A machine key opens its own file only; admin keys open everything but live on no machine.

| File | Machine key (at boot) | Admin keys (editing) |
|---|---|---|
| `secrets/kuri_exampleHost.yaml` | `/etc/sops/age/keys.txt` | YubiKey + rescue |
| `secrets/clochette.yaml` | derived from `/etc/ssh/ssh_host_ed25519_key` | YubiKey + rescue |
| `secrets/RogueLeader.yaml` | derived from `/etc/ssh/ssh_host_ed25519_key` | YubiKey + rescue |
| `secrets/skitarii.yaml` | derived from `/etc/ssh/ssh_host_ed25519_key` | YubiKey + rescue |

- **YubiKey**: age identity in PIV slot 1, not extractable. Needs `age-plugin-yubikey` and the PIV PIN (not the GPG PIN).
- **Rescue**: offline age key, for a lost YubiKey.
- No machine key is a recipient of another machine's file (#94).

Recipients in `.sops.yaml`, one rule per file:

```yaml
- path_regex: secrets/skitarii.yaml$
  key_groups:
  - age: [*server_skitarii, *admin_yubikey, *admin_rescue]
```

## Edit

```bash
just secrets_skitarii                  # sops secrets/skitarii.yaml, YubiKey plugged in
sops updatekeys secrets/skitarii.yaml  # after a recipient change (reinstall)
sops -d --extract '["services"]["ntfy"]["topic"]' secrets/clochette.yaml   # read one value
```

After changing a value: deploy, then `systemctl restart <container>`. No secret
has `restartUnits`, so the container keeps the old value until restarted.

## Reference

Declare the secret next to its service, read its path through `config`, never hardcode `/run/secrets/...`:

```nix
sops.secrets."services/papra/env" = {};
environmentFiles = [config.sops.secrets."services/papra/env".path];

# User password: decrypted before accounts are created
sops.secrets."users/guillaume/hashed-password".neededForUsers = true;
users.users.guillaume.hashedPasswordFile = config.sops.secrets."users/guillaume/hashed-password".path;
```

| Where | Path |
|---|---|
| System | `/run/secrets/` |
| `neededForUsers` | `/run/secrets-for-users/` |
| Home Manager (exampleHost) | `/run/user/1000/secrets/` |

Key backup: [Secrets backup](/nixos/operations/secrets-backup/).
