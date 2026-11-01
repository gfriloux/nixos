---
title: "Réinstaller clochette"
description: Du rescue Dedibox au premier déploiement, par nixos-anywhere depuis exampleHost.
---

:::danger
L'étape 5 efface le disque de clochette. Immich est injoignable jusqu'à la
restauration Borg (étape 9).
:::

| | |
|---|---|
| IP | `51.159.34.135`, passerelle `51.159.34.1` |
| Disque | `/dev/sda`, BIOS, GPT + EF02 (`disko.nix`) |
| Console | série Dedibox, noyau sur `ttyS1` |
| sops | clé age dérivée de `/etc/ssh/ssh_host_ed25519_key` |
| SSH | Tailscale seulement (`100.64.0.0/10`) |

## Avant

- Accès à la console Dedibox (mode rescue, console série).
- La YubiKey (`sops`) et la console d'admin Tailscale.
- Une archive Borg récente : [Restaurer depuis Borg](/nixos/fr/operations/restore/).

## 1. Basculer sur disko (définitif)

`disko.nix` existe mais n'est pas importé : l'installation actuelle est en MBR,
sans partlabel. À faire une seule fois, à la première réinstallation.

Dans `systems/x86_64-linux/clochette/default.nix` :

```nix
imports = [
  inputs.disko.nixosModules.disko
  ./disko.nix
  # …
];

boot.loader.grub.enable = true;   # remplace le bloc avec device = "/dev/sda" : disko le fournit
```

Dans `hardware-configuration.nix`, supprimer `fileSystems."/"`,
`fileSystems."/boot"` et `swapDevices`. Vérifier :

```bash
nix eval '.#nixosConfigurations.clochette.config.fileSystems."/".device'   # /dev/disk/by-partlabel/disk-main-root
```

Retirer ensuite le commentaire « Pas encore importé » de `disko.nix`.

## 2. Ouvrir le SSH public (temporaire)

La machine neuve n'est pas sur le tailnet. Dans `default.nix` :

```nix
openFirewall = true; # TEMPORAIRE : pas encore sur le tailnet
```

Ne pas commiter.

## 3. Générer la clé hôte

```bash
mkdir -p /tmp/clochette-extra/etc/ssh
ssh-keygen -q -t ed25519 -N "" -C root@clochette -f /tmp/clochette-extra/etc/ssh/ssh_host_ed25519_key
nix shell nixpkgs#ssh-to-age -c ssh-to-age < /tmp/clochette-extra/etc/ssh/ssh_host_ed25519_key.pub
ssh-keygen -lf /tmp/clochette-extra/etc/ssh/ssh_host_ed25519_key.pub   # empreinte à vérifier à l'étape 6
```

Mettre la clé age dans `&server_clochette` (`.sops.yaml`), puis :

```bash
sops updatekeys secrets/clochette.yaml   # YubiKey
```

## 4. Démarrer le rescue

Console Dedibox → clochette → **Rescue**. Le login et le mot de passe
s'affichent sur la page du serveur. Le rescue ouvre un utilisateur normal ;
nixos-anywhere veut root.

```bash
ssh-keygen -R 51.159.34.135
ssh-copy-id -o PubkeyAuthentication=no -i ~/.ssh/id_ed25519 <login>@51.159.34.135
ssh <login>@51.159.34.135 'sudo mkdir -p /root/.ssh && sudo cp ~/.ssh/authorized_keys /root/.ssh/ && lsblk'
ssh root@51.159.34.135 true
```

Si root est refusé, donner à `<login>` un sudo sans mot de passe et viser
`<login>@` à l'étape 5 :

```bash
ssh -t <login>@51.159.34.135 'echo "<login> ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/anywhere'
```

Si le disque n'est pas `sda` en rescue, mettre son nom dans `disko.nix` le
temps de l'installation, puis revenir à `/dev/sda` (comme pour
[skitarii](/nixos/fr/operations/reinstall-skitarii/)).

## 5. Installer

```bash
ssh-add ~/.ssh/id_ed25519
nix run github:nix-community/nixos-anywhere -- \
  --flake .#clochette \
  --target-host root@51.159.34.135 \
  --ssh-option IdentitiesOnly=yes \
  --ssh-option IdentityFile=$HOME/.ssh/id_ed25519.pub \
  --phases kexec,disko,install \
  --extra-files /tmp/clochette-extra
```

Pas de phase `reboot` : la machine repartirait en rescue. Après `Shared
connection closed`, attendre, nixos-anywhere reprend seul. Attendu :

```text
sops-install-secrets: Imported /etc/ssh/ssh_host_ed25519_key as age key with fingerprint age1…
installing the GRUB 2 boot loader on /dev/sda...
### Done! ###
```

L'empreinte age doit être celle de `.sops.yaml`.

## 6. Premier boot

Console Dedibox → sortir du rescue, redémarrer. La console série montre
`clochette login:`. Puis :

```bash
ssh-keygen -R 51.159.34.135
ssh -t -o HostName=51.159.34.135 -o IdentitiesOnly=yes clochette.friloux.me sudo true
```

N'accepter que l'empreinte notée à l'étape 3.

## 7. Tailscale

Console d'admin Tailscale : **supprimer l'ancienne entrée clochette** d'abord,
sinon le nœud devient `clochette-1` et le bloc ssh vise un nom mort.

```bash
sudo tailscale up            # sur clochette, ouvrir l'URL
```

Puis **⋯ → Disable key expiry**. Depuis exampleHost :

```bash
ssh-keygen -R clochette
ssh clochette.friloux.me true
```

## 8. Refermer le SSH public

Remettre `openFirewall = false;` dans `default.nix`, puis :

```bash
just install_clochette
nc -zv -w 5 51.159.34.135 22    # doit échouer en timeout
```

Commiter la bascule disko, `.sops.yaml` et `secrets/clochette.yaml`, puis
`rm -r /tmp/clochette-extra`.

## 9. Restaurer

Depuis Borg : `/srv/docker/photos.friloux.me` et `/home/weechat/.config/weechat`.
La base Immich se recharge depuis son dump, sinon elle démarre vide :
[Immich (clochette)](/nixos/fr/operations/restore/#immich-clochette).

## 10. Vérifier

```bash
docker ps --format "table {{.Names}}\t{{.Status}}"   # newt, immich-* healthy
docker logs newt --tail 20                           # tunnel vers skitarii
systemctl start borgbackup-job-remote && systemctl status borgbackup-job-remote
```

`https://photos.friloux.me` répond, et `irc.friloux.me` ouvre la session weechat.

## Dépannage

| Symptôme | Cause, remède |
|---|---|
| `Connection reset by peer` après un login raté | Ban d'une heure (`PerSourcePenalties`). Redémarrer depuis la console Dedibox, reprendre avec `IdentitiesOnly=yes`. |
| `sudo` refuse le mot de passe | Hash cassé dans sops, voir [skitarii](/nixos/fr/operations/reinstall-skitarii/#sudo-refuse-le-mot-de-passe). |
| Pas de SSH du tout | Console série Dedibox, login `guillaume`. |
