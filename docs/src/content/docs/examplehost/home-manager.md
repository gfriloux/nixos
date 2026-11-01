---
title: "Home Manager"
description: kuri's environment on exampleHost, secrets, SSH, fish, git, mail, software.
---

`homes/x86_64-linux/kuri@exampleHost/`, applied by `just install` with the system.

| File | Content |
|---|---|
| `default.nix` | STC modules, packages, sops, fish, git, theme |
| `ssh.nix` | SSH keys (sops), ssh-agent, hosts |
| `mail.nix` | friloux account: offlineimap, notmuch, aerc, alot, msmtp |

Imported STC modules: `cogitator-enginseer` (CLI tools, SSH multiplexing),
`cogitator-desktop`, `relics-yubikey-user`, `relics-plasma-manager`.

## Secrets

System age key `/etc/sops/age/keys.txt`, file `secrets/kuri_exampleHost.yaml`,
decrypted to `/run/user/1000/secrets/`.

| sops key | Use |
|---|---|
| `workspace` | Environment variables, loaded by fish |
| `rbw/server`, `mail/address` | `rbw-wrapper` (alias `rbw`) |
| `ssh/keys/*` | guillaume@clochette, weechat@clochette, guillaume@skitarii, kuri@storage2, root@rogueleader, github |
| `mail/password`, `mail/tags/*` | Mail account, notmuch tag rules |

## SSH

ssh-agent on `/run/user/1000/ssh-agent`. One key per host:

```nix
"skitarii.friloux.me" = {
  HostName = "skitarii";   # Tailscale name
  User = "guillaume";
  IdentityFile = config.sops.secrets."ssh/keys/guillaume@skitarii".path;
  IdentitiesOnly = true;   # one refused key = 1 h ban (PerSourcePenalties)
};
```

Other hosts: `clochette.friloux.me`, `irc.friloux.me` (weechat), `rogueleader.home`,
`storage2.friloux.me`, `github.com`, `arthur.home`, `baptiste.home`.

## Shell and git

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

`imapnotify` runs `offlineimap` on every new message (INBOX and Sent only),
then `notmuch new` tags. Read with aerc (views on tags) or alot, send with
msmtp. Server `mx.friloux.me`.

## Software

| Use | Packages |
|---|---|
| Games | Steam (system), Heroic, Wine staging, winetricks, protonup-ng, PCSX2, Ryubing, ScummVM, DOSBox-X |
| Desktop | Ghostty, kitty, Zen, GIMP, VLC, Vesktop, Transmission, Flameshot, Kooha, GParted |
| YubiKey | yubikey-manager, Yubico Authenticator, age-plugin-yubikey, pgpilot |
| Dev | claude-code, rustup, gcc, nodejs 22, gh, git-workspace, helix, micro, nixd |

The rest (CLI tools, fonts) comes from the STC modules.
