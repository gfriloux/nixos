---
title: "Réinstaller skitarii"
description: Du rescue OVH au premier déploiement, par nixos-anywhere depuis exampleHost.
---

:::danger
L'étape 4 efface le disque de skitarii. Tous les services publics passent
par skitarii : ils sont coupés jusqu'à la restauration Borg (étape 8).
:::

| | |
|---|---|
| IP | `5.196.4.180` (DHCP), IPv6 statique dans `network.nix` |
| Disque | `/dev/sda` en boot normal, **`/dev/sdb` en rescue** |
| Boot | BIOS, GPT + EF02 (`disko.nix`) |
| Console | aucune (VPS-1, pas de KVM) |
| sops | clé age dérivée de `/etc/ssh/ssh_host_ed25519_key` |
| SSH | Tailscale seulement |

## Avant

- Accès au manager OVH (redémarrer en rescue ou en mode normal).
- La YubiKey (`sops`) et la console d'admin Tailscale.
- Une archive Borg récente : [Restaurer depuis Borg](/nixos/fr/operations/restore/).

En rescue, le disque de rescue OVH prend `sda` et celui du VPS devient `sdb`.
disko tire le device de GRUB de `disko.nix` : on installe sur `sdb`, puis on
revient à `sda` (étape 6). Les `by-id` suivent l'adresse SCSI et changent
aussi.

## 1. Modifications temporaires

Ne pas commiter.

```nix
# disko.nix
device = "/dev/sdb"; # TEMPORAIRE : réinstallation depuis le rescue

# network.nix
services.openssh.openFirewall = true; # TEMPORAIRE : pas encore sur le tailnet
```

## 2. Générer la clé hôte

```bash
mkdir -p /tmp/skitarii-extra/etc/ssh
ssh-keygen -q -t ed25519 -N "" -C root@skitarii -f /tmp/skitarii-extra/etc/ssh/ssh_host_ed25519_key
nix shell nixpkgs#ssh-to-age -c ssh-to-age < /tmp/skitarii-extra/etc/ssh/ssh_host_ed25519_key.pub
ssh-keygen -lf /tmp/skitarii-extra/etc/ssh/ssh_host_ed25519_key.pub   # empreinte à vérifier à l'étape 5
```

Mettre la clé age dans `&server_skitarii` (`.sops.yaml`), puis :

```bash
sops updatekeys secrets/skitarii.yaml   # YubiKey
```

## 3. Démarrer le rescue

Manager OVH → le VPS → **Redémarrer en mode rescue**. OVH envoie le mot de
passe root. `PubkeyAuthentication=no` écarte les clés de l'agent : Debian
coupe après 6 clés proposées.

```bash
ssh-keygen -R 5.196.4.180
ssh-copy-id -o PubkeyAuthentication=no -i ~/.ssh/id_ed25519 root@5.196.4.180
```

## 4. Installer

```bash
ssh-add ~/.ssh/id_ed25519
nix run github:nix-community/nixos-anywhere -- \
  --flake .#skitarii \
  --target-host root@5.196.4.180 \
  --ssh-option IdentitiesOnly=yes \
  --ssh-option IdentityFile=$HOME/.ssh/id_ed25519.pub \
  --phases kexec,disko,install \
  --extra-files /tmp/skitarii-extra
```

`IdentityFile` sur le `.pub` : ssh signe par l'agent, sans redemander la
passphrase à chaque connexion. Pas de phase `reboot` : le VPS repartirait en
rescue. Après `Shared connection closed`, attendre, nixos-anywhere reprend
seul. Attendu :

```text
sops-install-secrets: Imported /etc/ssh/ssh_host_ed25519_key as age key with fingerprint age1…
installing the GRUB 2 boot loader on /dev/sdb...
### Done! ###
```

L'empreinte age doit être celle de `.sops.yaml`.

## 5. Premier boot

Manager OVH → **Redémarrer** en mode normal. Une minute plus tard :

```bash
ssh-keygen -R 5.196.4.180
ssh -t -o HostName=5.196.4.180 skitarii.friloux.me sudo true
```

N'accepter que l'empreinte notée à l'étape 2.

## 6. Retour à `/dev/sda`

Remettre `device = "/dev/sda";` dans `disko.nix`, puis :

```bash
NIX_SSHOPTS="-o HostName=5.196.4.180" just install_skitarii   # GRUB sur /dev/sda
```

## 7. Tailscale

Console d'admin Tailscale : **supprimer l'ancienne entrée skitarii** d'abord,
sinon le nœud devient `skitarii-1` et le bloc ssh vise un nom mort.

```bash
sudo tailscale up            # sur skitarii, ouvrir l'URL
```

Puis **⋯ → Disable key expiry**. Depuis exampleHost (pas de `KeyExpiry` =
désactivée) :

```bash
tailscale status --json | jq '.Peer[] | select(.HostName=="skitarii") | {TailscaleIPs, KeyExpiry}'
ssh-keygen -R skitarii
ssh skitarii.friloux.me true
```

## 8. Refermer le SSH public, restaurer

Remettre `openFirewall = false;` dans `network.nix`, puis :

```bash
just install_skitarii
nc -zv -w 5 5.196.4.180 22    # doit échouer en timeout
```

Restaurer pangolin depuis Borg (nœuds, ressources, utilisateurs, TOTP,
licence, clé WireGuard de gerbil) :
[Services SQLite (skitarii)](/nixos/fr/operations/restore/#services-sqlite-skitarii).
La licence Enterprise suit le host ID : si `/admin/license` la montre
inactive, la ressaisir. crowdsec réenregistre seul le bouncer depuis sops.

Commiter `.sops.yaml` et `secrets/skitarii.yaml`, puis `rm -r /tmp/skitarii-extra`.

## Dépannage

| Symptôme | Cause, remède |
|---|---|
| `Connection reset by peer` après un login raté | Ban d'une heure (`PerSourcePenalties`), en mémoire de sshd. Redémarrer depuis le manager OVH, reprendre avec `IdentitiesOnly`. |
| `skitarii.friloux.me` ne résout pas | `NXDOMAIN` en cache 3 h (SOA Gandi) sur chaque résolveur. Vérifier avec `@1.1.1.1`, utiliser `-o HostName=…` en attendant. |
| Home Manager : `config.fish would be clobbered` | fish a créé un `config.fish` vide au premier login. Le supprimer, relancer `home-manager-guillaume.service`. |

### `sudo` refuse le mot de passe

Un hash yescrypt valide commence par `$y$j9T$` :

```bash
sops -d --extract '["users"]["guillaume"]["hashed-password"]' secrets/skitarii.yaml | head -c 10; echo
```

Le réécrire sans passer par le presse-papier :

```bash
sops set secrets/skitarii.yaml '["users"]["guillaume"]["hashed-password"]' "$(mkpasswd -m yescrypt | jq -R .)"
```

Root ne se connecte pas en SSH et `guillaume` n'a pas sudo : aucun
déploiement ne corrige ça. Reprendre à l'étape 3, avec le même
`/tmp/skitarii-extra`.
