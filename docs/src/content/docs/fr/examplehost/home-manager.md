---
title: "Home Manager"
description: L'environnement de kuri sur exampleHost, secrets, SSH, fish, git, mail, logiciels.
---

`homes/x86_64-linux/kuri@exampleHost/`, appliqué par `just install` avec le système.

| Fichier | Contenu |
|---|---|
| `default.nix` | Modules STC, paquets, sops, fish, git, thème |
| `ssh.nix` | Clés SSH (sops), ssh-agent, hôtes |
| `mail.nix` | Compte friloux : offlineimap, notmuch, aerc, alot, msmtp |

Modules STC importés : `cogitator-enginseer` (outils CLI, SSH multiplexé),
`cogitator-desktop`, `relics-yubikey-user`, `relics-plasma-manager`.

## Secrets

Clé age système `/etc/sops/age/keys.txt`, fichier `secrets/kuri_exampleHost.yaml`,
déchiffrés dans `/run/user/1000/secrets/`.

| Clé sops | Usage |
|---|---|
| `workspace` | Variables d'environnement, chargées par fish |
| `rbw/server`, `mail/address` | `rbw-wrapper` (alias `rbw`) |
| `ssh/keys/*` | guillaume@clochette, weechat@clochette, guillaume@skitarii, kuri@storage2, root@rogueleader, github |
| `mail/password`, `mail/tags/*` | Compte mail, règles de tags notmuch |

## SSH

ssh-agent sur `/run/user/1000/ssh-agent`. Une clé par hôte :

```nix
"skitarii.friloux.me" = {
  HostName = "skitarii";   # nom Tailscale
  User = "guillaume";
  IdentityFile = config.sops.secrets."ssh/keys/guillaume@skitarii".path;
  IdentitiesOnly = true;   # une clé refusée = 1 h de ban (PerSourcePenalties)
};
```

Autres hôtes : `clochette.friloux.me`, `irc.friloux.me` (weechat), `rogueleader.home`,
`storage2.friloux.me`, `github.com`, `arthur.home`, `baptiste.home`.

## Shell et git

```nix
programs.fish.shellInitLast = ''
  envsource /run/user/1000/secrets/workspace
  set -gx SSH_AUTH_SOCK "/run/user/1000/ssh-agent"
'';
programs.git.signing = {
  key = "52381C92A5071464F3160D257D4216D8BDDA9A09";
  signByDefault = true;
};
home.sessionVariables.EDITOR = "micro";
```

## Mail

`imapnotify` lance `offlineimap` à chaque nouveau message (INBOX et Sent seulement),
puis `notmuch new` tague. Lecture avec aerc (vues sur les tags) ou alot, envoi
par msmtp. Serveur `mx.friloux.me`.

## Logiciels

| Usage | Paquets |
|---|---|
| Jeux | Steam (système), Heroic, Wine staging, winetricks, protonup-ng, PCSX2, Ryubing, ScummVM, DOSBox-X |
| Bureau | Ghostty, kitty, Zen, GIMP, VLC, Vesktop, Transmission, Flameshot, Kooha, GParted |
| YubiKey | yubikey-manager, Yubico Authenticator, age-plugin-yubikey, pgpilot |
| Dev | claude-code, rustup, gcc, nodejs 22, gh, git-workspace, helix, micro, nixd |

Le reste (outils CLI, polices) vient des modules STC.
