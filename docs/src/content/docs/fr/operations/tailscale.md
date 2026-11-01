---
title: "Tailscale"
description: Qui est sur le tailnet, enrôler une machine, que faire sans SSH.
---

Tailscale SaaS, compte GitHub `gfriloux`.

| Machine | Tailnet | SSH |
|---|---|---|
| exampleHost | oui | local |
| clochette | oui, `clochette` | tailnet seulement (`100.64.0.0/10` + `tailscale0` de confiance) |
| skitarii | oui, `skitarii` | tailnet seulement (`tailscale0` de confiance) |
| RogueLeader | **non** | LAN, `192.168.0.10` |

Le bloc ssh d'exampleHost vise les noms MagicDNS (`HostName = "clochette"`).

## Enrôler

1. [Console d'admin](https://login.tailscale.com/admin/machines) : supprimer
   l'ancienne entrée, sinon le nœud devient `clochette-1` et le bloc ssh vise
   un nom mort.
2. Sur la machine : `sudo tailscale up`, ouvrir l'URL.
3. Console d'admin, sur la ligne : **⋯ → Disable key expiry**.
4. Depuis exampleHost :

```bash
tailscale status --json | jq '.Peer[] | select(.HostName=="clochette") | {TailscaleIPs, KeyExpiry}'   # pas de KeyExpiry = désactivée
ssh-keygen -R clochette
ssh clochette.friloux.me true
```

Sans navigateur : [générer une auth key](https://login.tailscale.com/admin/settings/keys)
à usage unique, `sudo tailscale up --authkey=tskey-auth-…`, puis la supprimer.

## Sans SSH

Le tailnet est la seule porte SSH de clochette et skitarii : sans lui, aucun
déploiement ne passe.

| Machine | Recours |
|---|---|
| clochette | Console série Dedibox, login `guillaume`, `sudo tailscale up` |
| skitarii | Pas de console : [réinstaller](/nixos/fr/operations/reinstall-skitarii/) |

Diagnostic, une fois connecté :

```bash
tailscale status
ip link show tailscale0
sudo nft list ruleset | grep -A3 100.64     # clochette
```
