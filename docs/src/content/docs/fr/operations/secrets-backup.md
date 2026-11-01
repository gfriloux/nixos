---
title: "Sauvegarde des clés age"
description: Éditer avec la YubiKey, la clé de secours, vérifier les clés, se remettre d'une clé perdue.
---

Les fichiers sops sont dans git, sans danger sans les clés. Ce qui compte, c'est
la **clé de secours** : la seule liée à aucun appareil. Qui ouvre quoi :
[Secrets](/nixos/fr/architecture/secrets/).

## YubiKey

`sops` trouve la YubiKey par `~/.config/sops/age/keys.txt`, un fichier de
référence sans secret :

```text
#       Serial: 36644572, Slot: 1
#         Name: sops-master
#    Recipient: age1yubikey1qtsqgx98tq7d005aue4lqth3z5hgu67e9eee490mpf0phfx7znghqr8x67l
AGE-PLUGIN-YUBIKEY-1MSNZ7Q5ZKGQ5JCG67Q42J
```

| | |
|---|---|
| Plugin | `age-plugin-yubikey` dans le `PATH`, même pour chiffrer (relic `relics-yubikey-user`) |
| PIN | PIV, 6 à 8 caractères, une fois par session. Pas le PIN GPG ; plus long = `size error` |
| Toucher | à chaque déchiffrement, sous ~15 s, sinon `Failed to decrypt YubiKey stanza` |
| GnuPG | partage la carte via pcscd, inutile d'arrêter `scdaemon` ([stc#111](https://github.com/gfriloux/stc/issues/111)) |

## Clé de secours

Clé age simple, générée le 2026-10-25, hors ligne, sur aucune machine.
Publique : `age1faz4m9gj9xyz4rm26gndwgjkwrwr9ppnzm48slcrne7uvf3afqcsxtv8hs`.

```bash
SOPS_AGE_KEY_FILE=/tmp/rescue.txt sops secrets/clochette.yaml
shred -u /tmp/rescue.txt
```

## Vérifier

Quelques fois par an. Rien ne s'affiche en clair.

```bash
# YubiKey (ou la copie de secours) : ouvre les quatre
for f in kuri_exampleHost clochette RogueLeader skitarii; do
  SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops -d secrets/$f.yaml > /dev/null && echo "$f OK"
done

# Clé de boot d'exampleHost : son fichier seulement
for f in kuri_exampleHost clochette RogueLeader skitarii; do
  SOPS_AGE_KEY_FILE=/etc/sops/age/keys.txt sops -d secrets/$f.yaml > /dev/null 2>&1 \
    && echo "$f : ouvert" || echo "$f : refusé"
done
```

## Clé perdue

| Perdu | Remède |
|---|---|
| Clé de boot d'exampleHost | `age-keygen` vers `/etc/sops/age/keys.txt`, nouvelle clé dans `&desktop_examplehost`, `sops updatekeys` (YubiKey), `just install`. Pas de système : [Réinstaller exampleHost](/nixos/fr/operations/reinstall-examplehost/) |
| Clé hôte d'un serveur | Réinstaller : [clochette](/nixos/fr/operations/reinstall-clochette/), [RogueLeader](/nixos/fr/operations/reinstall-rogueleader/), [skitarii](/nixos/fr/operations/reinstall-skitarii/) |
| YubiKey | Clé de secours ; enrôler une nouvelle YubiKey, la mettre dans `&admin_yubikey`, `updatekeys` sur les quatre fichiers |
| Clé de secours | En générer une, la mettre dans `&admin_rescue`, `updatekeys` sur les quatre fichiers (YubiKey) |
| Les deux | Chaque machine lit encore son fichier : le rechiffrer depuis là vers de nouvelles clés d'admin |

:::danger
YubiKey et clé de secours perdues ensemble : plus aucune clé n'ouvre tous les
fichiers. Ranger la clé de secours loin de la YubiKey, et la tester.
:::
