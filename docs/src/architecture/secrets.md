# Gestion des secrets

Les secrets sont chiffrés avec [sops](https://github.com/getsops/sops)
et des clés [age](https://age-encryption.org/) via le module NixOS [sops-nix](https://github.com/Mic92/sops-nix).

## Modèle de clés

Chaque machine a sa propre clé age (privée/publique).
La clé privée de exampleHost peut déchiffrer **tous** les secrets — c'est la clé maîtresse.

| Machine | Type de clé | Emplacement privé |
|---|---|---|
| exampleHost | Fichier age dédié | `/etc/sops/age/keys.txt` |
| clochette | Dérivée de la clé SSH host | dérivée à la volée depuis `/etc/ssh/ssh_host_ed25519_key` |
| RogueLeader | Dérivée de la clé SSH host | dérivée à la volée depuis `/etc/ssh/ssh_host_ed25519_key` |

## Fichiers de secrets

| Fichier | Déchiffrable par |
|---|---|
| `secrets/kuri_exampleHost.yaml` | exampleHost uniquement |
| `secrets/clochette.yaml` | clochette + exampleHost |
| `secrets/RogueLeader.yaml` | RogueLeader + exampleHost |

## Déchiffrement au démarrage

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
```

La règle de chiffrement pour chaque fichier est définie sous `creation_rules`.

## Référence dans la config NixOS

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
