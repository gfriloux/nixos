---
title: Reliquaires de Secrets
description: Gestion des secrets via sops-nix et age — modèle de clés, fichiers chiffrés, références.
---

Les secrets sont chiffrés avec [sops](https://github.com/getsops/sops) et des clés [age](https://age-encryption.org/) via le module NixOS [sops-nix](https://github.com/Mic92/sops-nix).

## Modèle de Clés

Deux sortes de clés, aux rôles distincts :

- **Les clés de machine** déchiffrent le fichier de leur machine au démarrage.
  Chacune n'ouvre qu'un fichier : lire le disque d'une machine expose ses
  propres secrets, pas ceux des autres.
- **Les clés d'administration** servent à éditer les fichiers avec `sops`.
  Elles sont destinataires de tous les fichiers et ne sont jamais en clair sur
  une machine.

| Clé | Sorte | Partie privée | Ouvre |
|---|---|---|---|
| exampleHost | Machine, fichier age dédié | `/etc/sops/age/keys.txt` | `kuri_exampleHost.yaml` |
| clochette | Machine, dérivée de la clé SSH host | `/etc/ssh/ssh_host_ed25519_key` | `clochette.yaml` |
| RogueLeader | Machine, dérivée de la clé SSH host | `/etc/ssh/ssh_host_ed25519_key` | `RogueLeader.yaml` |
| YubiKey | Administration, identité age en PIV slot 1 | sur la YubiKey, non extractible | les trois |
| Secours | Administration, clé age simple | hors ligne, sur aucune machine | les trois |

## Fichiers de Reliquaires

| Fichier | Déchiffrable par |
|---|---|
| `secrets/kuri_exampleHost.yaml` | exampleHost + YubiKey + secours |
| `secrets/clochette.yaml` | clochette + YubiKey + secours |
| `secrets/RogueLeader.yaml` | RogueLeader + YubiKey + secours |

## Déchiffrement au Démarrage

sops-nix dépose les secrets déchiffrés dans `/run/secrets/` au démarrage du système.
Les secrets `neededForUsers = true` sont déposés dans `/run/secrets-for-users/`
avant la création des utilisateurs (pour les mots de passe hashés).

Sur exampleHost, Home Manager dépose ses secrets dans `/run/user/1000/secrets/`.

## Configuration sops (`.sops.yaml`)

```yaml
keys:
  - &desktop_examplehost age1xr32hdvanup0zk63v8hrcv2u2c09wplz6fd42w47mkjrd49j39xqaqqckq
  - &server_clochette     age18594hnd4mk3736a36a5fqc5w55sanac86tv8du0hz67rfk558srs3y9jwa
  - &server_rogueleader   age1nttxr633hf6r43szc9ffl2a0avmtmhtl7hhnjjuyd3sc4au705nqffyfwe
  - &admin_yubikey        age1yubikey1qtsqgx98tq7d005aue4lqth3z5hgu67e9eee490mpf0phfx7znghqr8x67l
  - &admin_rescue         age1faz4m9gj9xyz4rm26gndwgjkwrwr9ppnzm48slcrne7uvf3afqcsxtv8hs
```

La règle de chiffrement pour chaque fichier est définie sous `creation_rules`.

## Référence dans la Config NixOS

Toujours utiliser `config.sops.secrets."<chemin>".path` :

```nix
sops.secrets."services/papra/env" = {};

environmentFiles = [
  config.sops.secrets."services/papra/env".path
];
```

Ne jamais hardcoder `/run/secrets/...`.

Pour les mots de passe utilisateurs :

```nix
sops.secrets."users/kuri/hashed-password".neededForUsers = true;
users.users.kuri.hashedPasswordFile =
  config.sops.secrets."users/kuri/hashed-password".path;
```
