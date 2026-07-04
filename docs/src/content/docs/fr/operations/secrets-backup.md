---
title: Sauvegarde & Restauration des Secrets
description: Procédures critiques — clés age, sauvegarde hors-ligne, restauration.
---

Procédures essentielles pour protéger et restaurer les clés de chiffrement qui sécurisent tous les secrets de la Forge.

## Vue d'Ensemble

Les secrets sont chiffrés avec [sops-nix](https://github.com/Mic92/sops-nix) et des clés [age](https://age-encryption.org/).
Les fichiers chiffrés (`.yaml`) sont versionnés dans git — c'est sans risque, personne ne peut les lire
sans la clé privée correspondante. Ce qu'il faut **absolument** protéger, c'est la clé privée age de exampleHost.

### Fichiers de Secrets

| Fichier | Chiffré avec |
|---|---|
| `secrets/kuri_exampleHost.yaml` | clé age de exampleHost uniquement |
| `secrets/clochette.yaml` | clé age de clochette **+** clé age de exampleHost |
| `secrets/RogueLeader.yaml` | clé age de RogueLeader **+** clé age de exampleHost |

:::danger[Interdit]
**Point clé** : la clé age de exampleHost peut déchiffrer **tous** les secrets de l'infra.
C'est la clé maîtresse. Sa perte rend `kuri_exampleHost.yaml` irrecupérable.
:::

## Clés Age par Machine

### exampleHost

- **Type** : clé age dédiée, gérée manuellement
- **Emplacement** : `/etc/sops/age/keys.txt`
- **Permissions** : `0640 root:users` (lisible par le groupe `users`)
- **Clé publique** : `age1xr32hdvanup0zk63v8hrcv2u2c09wplz6fd42w47mkjrd49j39xqaqqckq`

C'est la seule clé qui doit être **sauvegardée hors-ligne**. Voir la procédure ci-dessous.

### clochette

- **Type** : clé age dérivée de la clé SSH host ed25519
- **Source** : `/etc/ssh/ssh_host_ed25519_key` (généré automatiquement à l'install)
- **Clé publique** : `age18594hnd4mk3736a36a5fqc5w55sanac86tv8du0hz67rfk558srs3y9jwa`

La clé privée age n'existe pas en tant que fichier : sops-nix la dérive à la volée depuis la clé SSH host.
Après une réinstallation, une nouvelle clé SSH host est générée → la clé age change → il faut mettre à jour `.sops.yaml`.

### RogueLeader

- **Type** : clé age dérivée de la clé SSH host ed25519
- **Source** : `/etc/ssh/ssh_host_ed25519_key` (explicite dans la config)
- **Clé publique** : `age1nttxr633hf6r43szc9ffl2a0avmtmhtl7hhnjjuyd3sc4au705nqffyfwe`

Même comportement que clochette.

## Ce qui est Déjà Sauvegardé

| Élément | Où | État |
|---|---|---|
| Fichiers secrets chiffrés (`*.yaml`) | Dépôt git | ✅ Versionné automatiquement |
| Configuration sops (`.sops.yaml`) | Dépôt git | ✅ Versionné automatiquement |
| Clé privée age de exampleHost | `/etc/sops/age/keys.txt` | ⚠️ À sauvegarder manuellement |
| Clés SSH host de clochette/RogueLeader | `/etc/ssh/ssh_host_ed25519_key` | ⚠️ Régénérées à chaque réinstall |

## Procédure de Sauvegarde — Clé Age de exampleHost

### Afficher la Clé Publique (Vérification)

Depuis exampleHost :

```bash
age-keygen -y /etc/sops/age/keys.txt
```

Résultat attendu :

```text
age1xr32hdvanup0zk63v8hrcv2u2c09wplz6fd42w47mkjrd49j39xqaqqckq
```

Si cette valeur ne correspond pas à la clé dans `.sops.yaml`, il y a un problème.

### Afficher la Clé Privée

```bash
sudo cat /etc/sops/age/keys.txt
```

Le contenu ressemble à :

```text
# created: 2024-01-01T00:00:00+01:00
# public key: age1xr32hdvanup0zk63v8hrcv2u2c09wplz6fd42w47mkjrd49j39xqaqqckq
AGE-SECRET-KEY-1XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

### Où Stocker la Sauvegarde

Stocker la clé privée dans **au moins deux** des emplacements suivants :

1. **Gestionnaire de mots de passe** (Bitwarden/rbw) : coller le contenu complet dans une note sécurisée
2. **Clé USB chiffrée** (LUKS) stockée hors site
3. **Impression papier** rangée dans un endroit sûr (coffre, etc.) — format texte suffit

Ne pas stocker la sauvegarde uniquement sur exampleHost lui-même.

## Procédure de Vérification

Vérifier régulièrement que la sauvegarde permet bien de déchiffrer les secrets.

Depuis exampleHost, avec la clé en place :

```bash
# Déchiffrer clochette.yaml (affiche les secrets en clair — ne pas laisser dans un terminal partagé)
sops -d secrets/clochette.yaml

# Déchiffrer kuri_exampleHost.yaml
sops -d secrets/kuri_exampleHost.yaml

# Déchiffrer RogueLeader.yaml
sops -d secrets/RogueLeader.yaml
```

Ces commandes doivent s'exécuter sans erreur. Si sops retourne `could not decrypt`, la clé est absente ou incorrecte.

## Procédure de Restauration — Clé Age de exampleHost

Situation : exampleHost a été réinstallé, la clé `/etc/sops/age/keys.txt` n'existe plus.

## 1. Créer le Répertoire

```bash
sudo mkdir -p /etc/sops/age
sudo chmod 750 /etc/sops/age
```

## 2. Restaurer la Clé depuis la Sauvegarde

Coller le contenu sauvegardé (clé privée complète) dans le fichier :

```bash
sudo micro /etc/sops/age/keys.txt
# ou
sudo tee /etc/sops/age/keys.txt << 'EOF'
# created: 2024-01-01T00:00:00+01:00
# public key: age1xr32hdvanup0zk63v8hrcv2u2c09wplz6fd42w47mkjrd49j39xqaqqckq
AGE-SECRET-KEY-1XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
EOF
```

## 3. Corriger les Permissions

```bash
sudo chmod 640 /etc/sops/age/keys.txt
sudo chown root:users /etc/sops/age/keys.txt
```

## 4. Vérifier

```bash
age-keygen -y /etc/sops/age/keys.txt
# Doit afficher : age1xr32hdvanup0zk63v8hrcv2u2c09wplz6fd42w47mkjrd49j39xqaqqckq

sops -d secrets/kuri_exampleHost.yaml
# Doit afficher le contenu déchiffré sans erreur
```

## 5. Relancer le Déploiement NixOS

```bash
just install
```

sops-nix re-dépose les secrets dans `/run/secrets` et `/run/user/1000/secrets`.

## Procédure Après Réinstallation de clochette ou RogueLeader

Quand clochette ou RogueLeader est réinstallé, une **nouvelle clé SSH host** est générée.
La clé age dérivée change, et elle ne correspond plus à celle dans `.sops.yaml`.
Il faut mettre à jour `.sops.yaml` et re-chiffrer les secrets concernés.

### 1. Récupérer la Nouvelle Clé Age Publique

Depuis la machine réinstallée (via Tailscale ou console) :

```bash
# Convertir la clé SSH host en clé age publique
nix run nixpkgs#ssh-to-age -- -i /etc/ssh/ssh_host_ed25519_key.pub
```

Exemple de résultat :

```text
age18594hnd4mk3736a36a5fqc5w55sanac86tv8du0hz67rfk558srs3y9jwa
```

### 2. Mettre à Jour `.sops.yaml`

Dans le dépôt git, remplacer l'ancienne clé publique par la nouvelle.

Pour clochette, modifier `.sops.yaml` :

```yaml
keys:
  - &server_clochette age1NOUVELLE_CLE_PUBLIQUE_ICI
```

Pour RogueLeader :

```yaml
keys:
  - &server_rogueleader age1NOUVELLE_CLE_PUBLIQUE_ICI
```

### 3. Re-chiffrer les Fichiers de Secrets

Depuis exampleHost (qui peut toujours déchiffrer grâce à sa clé maîtresse) :

```bash
# Pour clochette
sops updatekeys secrets/clochette.yaml

# Pour RogueLeader
sops updatekeys secrets/RogueLeader.yaml
```

`updatekeys` re-chiffre les secrets avec les clés définies dans `.sops.yaml`.
Confirmer avec `y` quand sops demande validation.

### 4. Vérifier et Committer

```bash
# Vérifier que les fichiers sont bien mis à jour
git diff secrets/

# Committer
git add .sops.yaml secrets/clochette.yaml  # ou secrets/RogueLeader.yaml
git commit -m "chore(secrets): rotate age key for clochette after reinstall"
```

### 5. Déployer

```bash
just install_clochette --ask-sudo-password
```

## Scénario Catastrophe — Clé Age de exampleHost Perdue sans Sauvegarde

Si la clé privée age de exampleHost est perdue **et** qu'aucune sauvegarde n'existe :

| Fichier | Situation |
|---|---|
| `kuri_exampleHost.yaml` | **Irrécupérable** — chiffré uniquement avec la clé perdue |
| `clochette.yaml` | Récupérable depuis clochette (via sa clé SSH host) |
| `RogueLeader.yaml` | Récupérable depuis RogueLeader (via sa clé SSH host) |

**Pour `kuri_exampleHost.yaml` : repartir de zéro**

```bash
# Générer une nouvelle clé age
age-keygen -o /etc/sops/age/keys.txt

# Afficher la nouvelle clé publique
age-keygen -y /etc/sops/age/keys.txt

# Mettre à jour .sops.yaml avec la nouvelle clé publique
# Remplacer desktop_examplehost dans .sops.yaml

# Recréer kuri_exampleHost.yaml depuis zéro
sops secrets/kuri_exampleHost.yaml
# Saisir manuellement tous les secrets (mots de passe, etc.)

# Re-chiffrer clochette.yaml et RogueLeader.yaml avec la nouvelle clé
sops updatekeys secrets/clochette.yaml
sops updatekeys secrets/RogueLeader.yaml

# Committer
git add .sops.yaml secrets/
git commit -m "chore(secrets): rotate all age keys after exampleHost key loss"
```

:::caution[Garde]
Cette situation souligne l'importance de la sauvegarde hors-ligne de `/etc/sops/age/keys.txt`.
:::
