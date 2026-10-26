---
title: skitarii — Le Sanctuaire-Porte
description: VPS-1 OVH, futur gateway pangolin. Système de base pour l'instant — SSH via Tailscale, sops, IPv6 statique.
---

Voici skitarii — le sanctuaire-porte, dressé sur un VPS-1 OVH pour devenir un
jour le point d'entrée unique vers tous les autres sanctuaires.

## Configuration

| Paramètre | Valeur |
|---|---|
| Rôle | Futur gateway (pangolin, gerbil, traefik, crowdsec, crowdsec-manager) |
| Hébergeur | OVH VPS-1 (4 Go de RAM, disque 40 Go) |
| IPv4 publique | `5.196.4.180` (DHCP) |
| IPv6 publique | `2001:41d0:404:200::487d/128` (statique, passerelle `2001:41d0:404:200::1`) |
| DNS | `skitarii.friloux.me` — A + AAAA chez Gandi, posés à la main |
| Tailscale | `100.118.203.120`, expiration de clé désactivée |
| Boot | BIOS, GRUB sur `/dev/sda` |
| Disque | `/dev/sda`, GPT via disko : 1M BIOS boot, 2G swap, `/` ext4 |
| sops | Clé age dérivée de `/etc/ssh/ssh_host_ed25519_key` |
| stateVersion | `26.05` |

## État Actuel

Aucun conteneur pour l'instant. Le sanctuaire ne porte que le système de base :

- relics STC `hardening.ssh` et `nixHousekeeping`
- SSH joignable **uniquement via Tailscale** (`openFirewall = false`, `tailscale0` de confiance)
- utilisateur `guillaume` : clés `sk-ssh-ed25519` (YubiKey, application `ssh:skitarii`,
  handle sous passphrase dans `kuri_exampleHost.yaml`) et clé perso ;
  hash du mot de passe dans `secrets/skitarii.yaml`
- Home Manager `guillaume@skitarii` (cogitator-enginseer), rattaché par snowfall

Les services arriveront un par un.

## Déploiement

```bash
just build_skitarii
just install_skitarii    # via le tailnet (bloc ssh HostName = skitarii)
just secrets_skitarii    # éditer secrets/skitarii.yaml
```

## Notes Importantes

- **Pas de console KVM sur un VPS-1.** Si SSH et Tailscale tombent tous les
  deux, la seule entrée est le mode rescue OVH — voir
  [Réinstallation — skitarii](../operations/reinstall-skitarii.md).
- **Une authentification SSH ratée coûte une heure de ban** à l'adresse
  source (`PerSourcePenalties = authfail:3600s`, relic ssh). Le bloc ssh fixe
  la clé avec `IdentitiesOnly`, donc ça n'arrive pas via
  `ssh skitarii.friloux.me`. Redémarrer le VPS lève le ban : il vit dans la
  mémoire de sshd.
- Après un premier switch qui ajoute les adresses IPv6, démarrer
  `network-addresses-ens3` à la main : il est lié à l'apparition de
  l'interface, déjà passée. Au boot, il démarre seul.
