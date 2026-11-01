---
title: "Dépannage"
description: Conteneurs, web public, sops, déploiement, SSH, Borg, ZFS, weechat.
---

## Conteneurs

Une unité par conteneur, du nom du conteneur (`immich-server`, `papra`…),
sauf newt : `docker-newt`.

```bash
docker inspect --format='{{json .State.Health}}' <nom> | jq   # derniers healthchecks
docker logs <nom> --tail 50
systemctl reset-failed <unité> && systemctl start <unité>
```

`stc-docker-health-watch@<nom>` regarde toutes les 30 s et tue un conteneur
`unhealthy` : systemd le relance. Si les relances échouent, l'unité passe `failed` et ntfy prévient.

## Un site public ne répond plus

Tout passe par skitarii : le newt de la machine, puis la passerelle.

```bash
docker logs newt --tail 50                                   # clochette ou RogueLeader
sudo docker logs traefik --tail 100                          # skitarii
sudo docker exec crowdsec cscli decisions list --ip <IP>     # skitarii, IP bannie ?
```

Suite : [La passerelle](/nixos/fr/skitarii/gateway/).

## sops ne déchiffre pas

La clé de la machine doit être celle de `.sops.yaml` :

```bash
sudo nix shell nixpkgs#age -c age-keygen -y /etc/sops/age/keys.txt                    # exampleHost
nix shell nixpkgs#ssh-to-age -c ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub        # serveurs
```

Différente : [Clé perdue](/nixos/fr/operations/secrets-backup/#clé-perdue).

## Le déploiement échoue

```bash
just build_clochette    # construire sans déployer (build, build_rogueleader, build_skitarii)
just test               # pre-commit sur tout le dépôt
```

Erreur réseau : relancer. Erreur d'évaluation : lire le message en entier.

## Pas de SSH

clochette et skitarii : [Tailscale](/nixos/fr/operations/tailscale/#sans-ssh).
`Connection reset by peer` après un login raté : ban d'une heure
(`PerSourcePenalties`), voir [skitarii](/nixos/fr/operations/reinstall-skitarii/#dépannage).

## Borg échoue

```bash
journalctl -u borgbackup-job-remote --since today
sudo BORG_PASSPHRASE=$(sudo cat /run/secrets/services/borg/passphrase) \
  BORG_RSH="ssh -i /run/secrets/services/borg/key/private" \
  borg info ssh://backup@storage2.friloux.me/~/clochette.friloux.me
```

| Cause | Remède |
|---|---|
| Clé hôte de storage2 changée | `knownHostsFiles` dans `backup.nix` |
| storage2 plein | côté storage2 |
| Verrou resté | `borg break-lock <dépôt>` |

## Pool ZFS dégradé (exampleHost)

```bash
zpool status -v
```

Nouveau disque : copier la table de l'autre (`sgdisk -R <nouveau> <restant>`,
puis `sgdisk -G <nouveau>`), `zpool replace` sur **bpool et rpool**, mettre
son ID dans `disko.nix` **et** `boot.nix`, puis `just install` (GRUB sur les
deux disques). Suivre : `zpool status -w rpool`.

## Session weechat perdue

```bash
ssh irc.friloux.me
zellij attach      # ou `zellij` puis `weechat` si la session n'existe plus
```
