---
title: Tailscale — Ré-enrôlement
description: Procédure de ré-enrôlement Tailscale après réinstallation — authentification, vérification.
---

Procédure de ré-enrôlement Tailscale après réinstallation d'une machine.

## Topologie Actuelle

| Machine | Rôle Tailscale | Accès SSH |
|---|---|---|
| exampleHost | client/admin | via Tailscale ou local |
| clochette | serveur exposé | **uniquement via Tailscale** |
| RogueLeader | serveur interne | via réseau local ou Tailscale |

SSH sur clochette n'est accessible que depuis `100.64.0.0/10` (réseau Tailscale).
Après une réinstallation sans Tailscale opérationnel, utiliser la console série.

## Avant de Réinstaller — Supprimer l'Ancienne Entrée

Depuis le panel Tailscale Admin :
<https://login.tailscale.com/admin/machines>

Trouver la machine concernée (état "offline" ou "expired"), puis **Delete** ou **Expire**.

Si non supprimée, le ré-enrôlement crée un doublon avec le même hostname.

## Ré-enrôlement Interactif (Méthode Standard)

Sur la machine à enrôler :

```bash
sudo tailscale up
```

Tailscale affiche une URL d'authentification :

```text
To authenticate, visit:

        https://login.tailscale.com/a/XXXXXXXXXX
```

Ouvrir l'URL dans un navigateur, se connecter au compte Tailscale, approuver la machine.

Vérifier :

```bash
tailscale status
# La machine doit apparaître dans la liste avec une adresse 100.x.x.x
```

## Ré-enrôlement sans Navigateur (authkey)

Si le serveur n'a pas d'interface graphique et que la console série ne permet pas d'afficher l'URL facilement, générer une authkey depuis le panel :

1. Aller sur <https://login.tailscale.com/admin/settings/keys>
2. **Generate auth key** → One-time use, pas d'expiration courte
3. Copier la clé

Sur la machine :

```bash
sudo tailscale up --authkey=tskey-auth-XXXXXXXXXXXXXXXX
```

La machine s'enrôle sans interaction navigateur.

:::note[Marginalia]
Supprimer la clé authkey après usage depuis le panel.
:::

## Vérification de la Connectivité

Depuis exampleHost, après enrôlement :

```bash
# Statut global
tailscale status

# Latence vers clochette
tailscale ping clochette

# SSH via Tailscale
ssh guillaume@clochette.friloux.me

# SSH vers RogueLeader
ssh guillaume@rogueleader.home
```

## Si SSH Reste Inaccessible après Enrôlement

Sur clochette, vérifier la règle firewall (depuis console série) :

```bash
# La règle doit accepter le port 22 depuis 100.64.0.0/10
sudo nft list ruleset | grep -A3 "100.64"
# ou
sudo iptables -L INPUT -n | grep 22
```

Vérifier que l'interface Tailscale est bien `tailscale0` :

```bash
ip link show tailscale0
tailscale ip -4
```

Si l'interface s'appelle différemment, vérifier la config NixOS :

```nix
# clochette/default.nix
networking.firewall.trustedInterfaces = ["tailscale0"];
```

## Ré-enrôlement sans Accès Console (Urgence)

Si la console série est inaccessible et Tailscale n'est pas opérationnel,
la seule option est d'ouvrir temporairement le SSH public.

Modifier `clochette/network.nix` pour ajouter une règle temporaire :

```nix
networking.firewall.extraInputRules = ''
  ip saddr 100.64.0.0/10 tcp dport 22 accept
  ip saddr TON.IP.PUBLIQUE.ICI tcp dport 22 accept  # temporaire
'';
```

Déployer depuis exampleHost, finaliser le ré-enrôlement Tailscale,
puis **supprimer immédiatement** la règle temporaire et redéployer.
