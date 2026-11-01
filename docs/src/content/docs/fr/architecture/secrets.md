---
title: "Secrets"
description: sops-nix et age, qui ouvre quel fichier, éditer, référencer un secret.
---

[sops-nix](https://github.com/Mic92/sops-nix), chiffrement [age](https://age-encryption.org/).
Une clé de machine n'ouvre que son fichier ; les clés d'admin ouvrent tout mais ne sont sur aucune machine.

| Fichier | Clé de machine (au boot) | Clés d'admin (édition) |
|---|---|---|
| `secrets/kuri_exampleHost.yaml` | `/etc/sops/age/keys.txt` | YubiKey + secours |
| `secrets/clochette.yaml` | dérivée de `/etc/ssh/ssh_host_ed25519_key` | YubiKey + secours |
| `secrets/RogueLeader.yaml` | dérivée de `/etc/ssh/ssh_host_ed25519_key` | YubiKey + secours |
| `secrets/skitarii.yaml` | dérivée de `/etc/ssh/ssh_host_ed25519_key` | YubiKey + secours |

- **YubiKey** : identité age en PIV slot 1, non extractible. Demande `age-plugin-yubikey` et le PIN PIV (différent du PIN GPG).
- **Secours** : clé age hors ligne, pour une YubiKey perdue.
- Aucune clé de machine n'est destinataire du fichier d'une autre (#94).

Destinataires dans `.sops.yaml`, une règle par fichier :

```yaml
- path_regex: secrets/skitarii.yaml$
  key_groups:
  - age: [*server_skitarii, *admin_yubikey, *admin_rescue]
```

## Éditer

```bash
just secrets_skitarii                  # sops secrets/skitarii.yaml, YubiKey branchée
sops updatekeys secrets/skitarii.yaml  # après un changement de destinataires (réinstallation)
```

## Référencer

Déclarer le secret à côté du service, lire son chemin via `config`, jamais `/run/secrets/...` en dur :

```nix
sops.secrets."services/papra/env" = {};
environmentFiles = [config.sops.secrets."services/papra/env".path];

# Mot de passe utilisateur : déchiffré avant la création des comptes
sops.secrets."users/guillaume/hashed-password".neededForUsers = true;
users.users.guillaume.hashedPasswordFile = config.sops.secrets."users/guillaume/hashed-password".path;
```

| Où | Chemin |
|---|---|
| Système | `/run/secrets/` |
| `neededForUsers` | `/run/secrets-for-users/` |
| Home Manager (exampleHost) | `/run/user/1000/secrets/` |

Sauvegarde des clés : [Sauvegarde des secrets](/nixos/fr/operations/secrets-backup/).
