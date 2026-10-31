---
title: "skitarii"
description: VPS-1 OVH, la passerelle pangolin. SSH par Tailscale uniquement.
sidebar:
  order: 1
  label: "Vue d’ensemble"
---

Seule entrée publique : [Passerelle](/nixos/fr/skitarii/gateway/).

| | |
|---|---|
| Hébergeur | OVH VPS-1 (4 Go de RAM, disque 40 Go) |
| IPv4 | `5.196.4.180` (DHCP) |
| IPv6 | `2001:41d0:404:200::487d/128` statique, passerelle `2001:41d0:404:200::1` |
| DNS | `skitarii.friloux.me` A + AAAA chez Gandi (à la main). `pangolin`, `crowdsec` en sont des CNAME |
| Tailscale | `100.118.203.120`, expiration de clé désactivée |
| Disque | `/dev/sda`, GPT via disko : 1M BIOS boot, 2G swap, `/` ext4. GRUB, BIOS |
| sops | clé age dérivée de `/etc/ssh/ssh_host_ed25519_key` |
| Relics STC | `hardening.ssh`, `nixHousekeeping` |
| SSH | Tailscale uniquement (`openFirewall = false`, `tailscale0` de confiance) |
| `guillaume` | YubiKey `sk-ssh-ed25519` (application `ssh:skitarii`, handle dans `kuri_exampleHost.yaml`) + clé perso. Hash du mot de passe dans `secrets/skitarii.yaml` |
| Home Manager | `guillaume@skitarii` (cogitator-enginseer) |
| stateVersion | `26.05` |

## Déployer

```bash
just build_skitarii
just install_skitarii    # via le tailnet (bloc ssh HostName = skitarii)
just secrets_skitarii    # éditer secrets/skitarii.yaml
```

## Attention

- **Pas de console KVM.** SSH et Tailscale tombés : mode rescue OVH uniquement, voir [Réinstaller skitarii](/nixos/fr/operations/reinstall-skitarii/).
- **Une auth SSH ratée = 1 h de ban** pour l'adresse source (`PerSourcePenalties = authfail:3600s`). Le bloc ssh fixe la clé (`IdentitiesOnly`). Un redémarrage lève le ban (il vit dans la mémoire de sshd).
- **Premier switch qui ajoute les adresses IPv6 :** démarrer `network-addresses-ens3` à la main. Au boot, il démarre seul.
