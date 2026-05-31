---
title: sops-nix & Secrets
description: Gestion quotidienne des secrets — édition, lecture, ajout, rotation.
---

Référence pour la gestion quotidienne des secrets avec sops-nix.

Pour les procédures de sauvegarde et restauration, voir [Sauvegarde & Restauration des Secrets](secrets-backup.md).

## Éditer un Fichier de Secrets

```bash
# Ouvrir dans $EDITOR (déchiffre → édite → rechiffre à la fermeture)
sops secrets/clochette.yaml
sops secrets/kuri_exampleHost.yaml
sops secrets/RogueLeader.yaml

# Raccourcis via just
just secrets            # kuri_exampleHost.yaml
just secrets_clochette  # clochette.yaml
just secrets_rogueleader  # RogueLeader.yaml
```

## Lire un Secret sans l'Éditer

```bash
# Déchiffrer et afficher en clair
sops -d secrets/clochette.yaml

# Extraire une seule valeur (format YAML imbriqué avec .)
sops -d --extract '["services"]["ntfy"]["topic"]' secrets/clochette.yaml
```

## Ajouter un Nouveau Secret

1. Ouvrir le fichier avec `sops secrets/clochette.yaml`
2. Ajouter la clé/valeur en clair — sops la chiffre à la sauvegarde
3. Déclarer le secret dans la config NixOS de la machine concernée :

```nix
# Dans le fichier docker-*.nix ou default.nix de la machine
sops.secrets."services/monservice/env" = {};
```

4. Référencer dans la config du container :

```nix
virtualisation.oci-containers.containers."monservice" = {
  environmentFiles = [
    config.sops.secrets."services/monservice/env".path
  ];
};
```

:::tip[Cantique]
Déclarer les secrets près du service qui les utilise (dans le fichier `docker-*.nix`),
pas dans `default.nix`.
:::

## Emplacements des Secrets Déchiffrés

Au runtime, les secrets se trouvent dans :

| Machine | Emplacement | Usage |
|---|---|---|
| clochette | `/run/secrets/<nom>` | Secrets système (containers, users) |
| exampleHost | `/run/secrets/<nom>` | Secrets système |
| exampleHost (HM) | `/run/user/1000/secrets/<nom>` | Secrets Home Manager (kuri) |

Référencer un secret dans un service systemd ou shell :

```bash
cat /run/secrets/services/ntfy/topic
```

Dans la config NixOS, toujours utiliser `config.sops.secrets."<nom>".path`
pour obtenir le chemin — ne jamais hardcoder `/run/secrets/...`.

## Structure des Fichiers de Secrets

```yaml
# secrets/clochette.yaml (structure déchiffrée)
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

## Rotation d'un Secret

Pour changer la valeur d'un secret existant :

```bash
sops secrets/clochette.yaml
# Modifier la valeur, sauvegarder
```

Puis redéployer pour que sops-nix dépose la nouvelle valeur dans `/run/secrets` :

```bash
just install_clochette --ask-sudo-password
```

Les containers qui lisent via `environmentFiles` redémarrent automatiquement
après le redéploiement grâce à systemd.

## Ajouter une Machine aux Règles de Chiffrement

Quand une nouvelle machine est ajoutée au flake, lui permettre de déchiffrer ses secrets :

1. Obtenir sa clé age publique :
   - Si fichier age dédié : `age-keygen -y /etc/sops/age/keys.txt`
   - Si dérivée SSH : `ssh-to-age -i /etc/ssh/ssh_host_ed25519_key.pub`

2. Ajouter dans `.sops.yaml` :

```yaml
keys:
  - &nouvelle_machine age1XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
creation_rules:
  - path_regex: secrets/nouvelle_machine.yaml$
    key_groups:
    - age:
      - *nouvelle_machine
      - *desktop_examplehost  # toujours inclure exampleHost pour pouvoir éditer
```

3. Créer le fichier de secrets :

```bash
sops secrets/nouvelle_machine.yaml
```
