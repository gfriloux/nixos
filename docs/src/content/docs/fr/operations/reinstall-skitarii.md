---
title: Réinstallation — skitarii
description: Réinstaller le VPS OVH depuis le mode rescue avec nixos-anywhere — clé hôte, nom du disque, Tailscale.
---

Guide complet de réinstallation du sanctuaire-porte skitarii. OVH ne propose
pas d'image NixOS et un VPS-1 n'a pas de console KVM : tout passe par le
**mode rescue** et nixos-anywhere, lancé depuis exampleHost.

:::caution[Garde]
Le SSH de skitarii n'est joignable que via Tailscale. Une machine fraîchement
installée n'est pas encore sur le tailnet : le SSH public est donc rouvert le
temps de la réinstallation (étape 1) et refermé à la fin (étape 8). Ne pas
sauter la dernière étape.
:::

## Informations de Référence

| Paramètre | Valeur |
|---|---|
| IPv4 publique | `5.196.4.180` |
| Disque | `/dev/sda` en boot normal, **`/dev/sdb` en rescue** |
| Boot | BIOS, GRUB (GPT + partition EF02 via disko) |
| sops | Clé age dérivée de `/etc/ssh/ssh_host_ed25519_key` |
| SSH après réinstallation | Uniquement via Tailscale, `ssh skitarii.friloux.me` |

## Pré-Requis

- [ ] Accès au manager OVH (redémarrage en rescue / en mode normal)
- [ ] La YubiKey (identité age pour `sops`, clé ssh `ssh:skitarii`)
- [ ] Accès à la console d'admin Tailscale (connexion GitHub, `gfriloux`)

## Pourquoi le Nom du Disque Change

En mode rescue, OVH attache son propre disque de rescue en `sda` ; le disque
du VPS devient `sdb`. En boot normal, il redevient `sda`. Les noms
`/dev/disk/by-id` n'aident pas : ils suivent l'adresse SCSI, qui change aussi.

disko déduit `boot.loader.grub.devices` de son `device` : l'installation doit
donc viser `/dev/sdb`, et la config doit revenir à `/dev/sda` avant le switch
suivant — sinon `grub-install` vise un disque qui n'existe pas.

## Étape 1 — Modifications Temporaires du Flake

Dans `systems/x86_64-linux/skitarii/disko.nix` :

```nix
device = "/dev/sdb"; # TEMPORAIRE : réinstallation depuis le rescue
```

Dans `systems/x86_64-linux/skitarii/network.nix` :

```nix
services.openssh.openFirewall = true; # TEMPORAIRE : pas encore sur le tailnet
```

Ne pas commiter ces deux changements.

## Étape 2 — Générer la Clé Hôte à l'Avance

La clé hôte détermine la clé age : elle est donc créée sur exampleHost et
remise à l'installeur. sops fonctionne dès le premier boot.

```bash
mkdir -p /tmp/skitarii-extra/etc/ssh
ssh-keygen -q -t ed25519 -N "" -C root@skitarii -f /tmp/skitarii-extra/etc/ssh/ssh_host_ed25519_key
nix shell nixpkgs#ssh-to-age -c ssh-to-age < /tmp/skitarii-extra/etc/ssh/ssh_host_ed25519_key.pub
```

Remplacer la valeur de `&server_skitarii` dans `.sops.yaml` par cette clé age,
puis re-chiffrer (YubiKey) :

```bash
sops updatekeys secrets/skitarii.yaml
```

Noter la nouvelle empreinte, pour la vérifier à la première connexion :

```bash
ssh-keygen -lf /tmp/skitarii-extra/etc/ssh/ssh_host_ed25519_key.pub
```

## Étape 3 — Démarrer le Rescue

Manager OVH → le VPS → **Redémarrer en mode rescue**. OVH communique le mot
de passe root du rescue.

Depuis exampleHost, copier la clé dans le rescue. `PubkeyAuthentication=no`
écarte les clés de l'agent : Debian coupe la connexion après 6 clés proposées.

```bash
ssh-keygen -R 5.196.4.180
ssh-copy-id -o PubkeyAuthentication=no -i ~/.ssh/id_ed25519 root@5.196.4.180
```

## Étape 4 — Installer avec nixos-anywhere

:::danger[Interdit]
Destructif et irréversible. Efface entièrement le disque du VPS.
:::

```bash
nix run github:nix-community/nixos-anywhere -- \
  --flake .#skitarii \
  --target-host root@5.196.4.180 \
  --ssh-option IdentitiesOnly=yes \
  --ssh-option IdentityFile=$HOME/.ssh/id_ed25519.pub \
  --phases kexec,disko,install \
  --extra-files /tmp/skitarii-extra
```

- `IdentityFile` pointe sur le **`.pub`** : ssh demande la signature à l'agent
  au lieu de redemander la passphrase à chacune des nombreuses connexions de
  nixos-anywhere. Lancer `ssh-add ~/.ssh/id_ed25519` avant.
- Pas de phase `reboot` : le VPS redémarrerait en rescue.
- Après `machine will boot into nixos in 6s...` et `Shared connection
  closed`, **attendre** : nixos-anywhere attend que l'installeur démarre,
  puis continue seul.

Attendu à la fin :

```text
sops-install-secrets: Imported /etc/ssh/ssh_host_ed25519_key as age key with fingerprint age1…
installing the GRUB 2 boot loader on /dev/sdb...
### Done! ###
```

L'empreinte age doit être celle inscrite dans `.sops.yaml`.

## Étape 5 — Premier Boot

Manager OVH → **Redémarrer** en mode normal (sortie du rescue). Environ une
minute plus tard :

```bash
ssh-keygen -R 5.196.4.180
ssh -t -o HostName=5.196.4.180 skitarii.friloux.me sudo true
```

N'accepter que l'empreinte notée à l'étape 2. Si `sudo` refuse le mot de
passe, voir [Dépannage](#dépannage).

## Étape 6 — Retour à `/dev/sda`

Remettre `device = "/dev/sda";` dans `disko.nix`, puis :

```bash
NIX_SSHOPTS="-o HostName=5.196.4.180" just install_skitarii
```

Attendu : `installing the GRUB 2 boot loader on /dev/sda...`.

## Étape 7 — Tailscale

Dans la [console d'admin](https://login.tailscale.com/admin/machines),
**supprimer d'abord l'ancienne entrée skitarii** : sinon le nouveau nœud
s'appelle `skitarii-1` et le nom MagicDNS `skitarii` utilisé par le bloc ssh
ne pointe plus nulle part.

Sur skitarii :

```bash
sudo tailscale up
```

Ouvrir l'URL, valider, puis sur la ligne skitarii : **⋯ → Disable key
expiry**. Vérifier depuis exampleHost (pas de `KeyExpiry` = désactivée) :

```bash
tailscale status --json | jq '.Peer[] | select(.HostName=="skitarii") | {TailscaleIPs, KeyExpiry}'
ssh-keygen -R skitarii
ssh -o HostName=skitarii skitarii.friloux.me true
```

## Étape 8 — Refermer le SSH Public

Remettre `services.openssh.openFirewall = false;` dans `network.nix`, déployer
via le tailnet et vérifier que le port 22 ne répond plus :

```bash
just install_skitarii
ssh skitarii.friloux.me true
nc -zv -w 5 5.196.4.180 22    # doit échouer en timeout
```

Les données de pangolin (`/srv/docker/pangolin.friloux.me`) ne sont **pas
encore sauvegardées** : après réinstallation, pangolin repart vide. Refaire
sa configuration initiale (jeton dans `sudo docker logs pangolin`), réactiver
le TOTP, recréer le site local et les ressources (`crowdsec.friloux.me` →
`http://crowdsec-manager:8080`, SSO actif). crowdsec réenregistre seul le
bouncer depuis sops.

Commiter `.sops.yaml` et `secrets/skitarii.yaml`, puis supprimer la copie
locale de la clé hôte :

```bash
rm -r /tmp/skitarii-extra
```

## Dépannage

### `Connection reset by peer` juste après un login raté

sshd a banni l'adresse source pour une heure (`PerSourcePenalties =
authfail:3600s`). Sans console KVM, redémarrer le VPS depuis le manager OVH :
le ban vit dans la mémoire de sshd. Puis se connecter avec la bonne clé
uniquement (`IdentitiesOnly`).

### `sudo` refuse le mot de passe

Vérifier ce que contient sops — un hash yescrypt valide commence par `$y$j9T$` :

```bash
sops -d --extract '["users"]["guillaume"]["hashed-password"]' secrets/skitarii.yaml | head -c 10; echo
```

Un copier-coller peut perdre le préfixe. Écrire le hash sans passer par le
presse-papier :

```bash
sops set secrets/skitarii.yaml '["users"]["guillaume"]["hashed-password"]' "$(mkpasswd -m yescrypt | jq -R .)"
```

Root ne peut pas se connecter en SSH et `guillaume` ne peut pas faire `sudo` :
aucun déploiement ne peut corriger ça. Refaire la réinstallation depuis
l'étape 3, en gardant le même `/tmp/skitarii-extra`.

### `skitarii.friloux.me` ne résout pas après création de l'enregistrement

Demander un nom avant qu'il existe met le `NXDOMAIN` en cache pour la durée
minimale du SOA — 3 heures chez Gandi — sur chaque résolveur du chemin
(`100.100.100.100` de Tailscale, la box). Vérifier avec `@1.1.1.1` ; en
attendant, utiliser `-o HostName=…`.

### Home Manager échoue : `config.fish would be clobbered`

fish a écrit un `~/.config/fish/config.fish` vide au premier login, avant que
le home existe. Le supprimer et relancer `home-manager-guillaume.service`.
