# Commandes de déploiement

Référence des commandes utilisées pour construire et déployer les configurations NixOS.
Toutes les commandes `just` s'exécutent depuis la racine du dépôt.

---

## exampleHost (local)

```bash
# Tester la config sans l'appliquer (build seul)
just build

# Appliquer la config (équivalent de nixos-rebuild switch)
just install
```

`just install` exécute `nh os switch .` qui applique la configuration système
et active Home Manager pour l'utilisateur courant.

---

## clochette (distant via SSH Tailscale)

```bash
# Construire uniquement
just build_clochette

# Déployer
just install_clochette --ask-sudo-password
```

La commande complète sous-jacente :

```bash
nixos-rebuild switch \
  --flake .#clochette \
  --target-host guillaume@clochette.friloux.me \
  --sudo \
  --ask-sudo-password
```

> **Pré-requis** : Tailscale actif sur les deux machines et `clochette.friloux.me`
> résolu vers l'IP Tailscale. SSH doit être fonctionnel.

---

## RogueLeader (distant via réseau local)

```bash
# Construire uniquement
just build_rogueleader

# Déployer le système
just install_rogueleader --ask-sudo-password

# Déployer Home Manager uniquement
just home_rogueleader
```

---

## Vérification avant déploiement

```bash
# Lancer tous les linters (statix, deadnix, alejandra) via pre-commit
just test

# Évaluer le flake sans construire
nix flake check
```

---

## Rollback

Si un déploiement produit un système instable :

```bash
# Lister les générations NixOS
nixos-rebuild list-generations

# Revenir à la génération précédente (sur la machine cible)
nixos-rebuild switch --rollback

# Ou activer une génération spécifique au démarrage
# (sélectionner dans GRUB au prochain reboot)
```

Pour clochette via SSH :

```bash
ssh guillaume@clochette.friloux.me \
  "sudo nixos-rebuild switch --rollback"
```

---

## Édition des secrets

```bash
# Secrets exampleHost
just secrets

# Secrets clochette
just secrets_clochette

# Secrets RogueLeader
just secrets_rogueleader
```

Ces commandes ouvrent le fichier chiffré dans `$EDITOR` via `sops`.
Sauvegarder et quitter rechiffre automatiquement.

---

## Scan de sécurité des images Docker

```bash
just scan
```

Lance Trivy sur toutes les images Docker de la config clochette
et affiche les vulnérabilités HIGH et CRITICAL.

---

## Mise à jour des dépendances flake

```bash
just update
```

Met à jour `flake.lock` avec les dernières révisions de tous les inputs.
À suivre d'un `just build_clochette` pour vérifier que rien ne casse.
