---
title: Sauvegarde & Restauration des Secrets
description: Qui détient quelle clé, éditer les secrets avec la YubiKey, et se remettre d'une clé perdue ou d'une réinstallation.
---

Les secrets sont chiffrés avec [sops-nix](https://github.com/Mic92/sops-nix) et des clés [age](https://age-encryption.org/).
Les fichiers chiffrés (`.yaml`) sont versionnés dans git — sans danger sans les clés privées.
Ce qu'il faut protéger, c'est la **clé de secours**, la seule qui ne soit liée à aucun appareil.

## Qui détient quelle clé

| Clé | Rôle | Partie privée | Ouvre |
|---|---|---|---|
| exampleHost | Démarrage d'exampleHost | `/etc/sops/age/keys.txt` (en clair, `0640 root:users`) | `kuri_exampleHost.yaml` |
| clochette | Démarrage de clochette | dérivée de `/etc/ssh/ssh_host_ed25519_key` | `clochette.yaml` |
| RogueLeader | Démarrage de RogueLeader | dérivée de `/etc/ssh/ssh_host_ed25519_key` | `RogueLeader.yaml` |
| YubiKey | Édition avec `sops` | YubiKey 5 NFC (série 36644572), PIV slot 1 | les trois |
| Secours | Édition si la YubiKey est perdue | hors ligne, sur aucune machine | les trois |

Les clés publiques et les destinataires de chaque fichier sont dans `.sops.yaml`.

Une clé de machine n'ouvre que son propre fichier. Lire le disque d'exampleHost
expose les secrets d'exampleHost — dont des clés SSH vers les serveurs — mais
pas les fichiers sops des serveurs. **Ne jamais ajouter une clé de machine
comme destinataire du fichier d'une autre machine** : on retrouverait une clé
unique qui ouvre tout.

## Éditer les secrets avec la YubiKey

`sops` trouve la YubiKey via un fichier de référence, qui ne contient aucun
secret (numéro de série, slot et une étiquette publique). Il se trouve dans
`~/.config/sops/age/keys.txt` :

```text
#       Serial: 36644572, Slot: 1
#         Name: sops-master
#    Recipient: age1yubikey1qtsqgx98tq7d005aue4lqth3z5hgu67e9eee490mpf0phfx7znghqr8x67l
AGE-PLUGIN-YUBIKEY-1MSNZ7Q5ZKGQ5JCG67Q42J
```

`sops` a besoin d'`age-plugin-yubikey` dans le `PATH`, même pour chiffrer. Le
relic `relics-yubikey-user` de STC l'installe :

```bash
sops secrets/clochette.yaml
```

- **PIN** : le PIN PIV, de 6 à 8 caractères. Ce n'est pas le PIN GPG
  (OpenPGP). Un PIN plus long échoue avec `size error` avant même que la
  YubiKey le vérifie. Demandé une fois par session.
- **Toucher** : nécessaire à chaque déchiffrement.
- **`Failed to decrypt YubiKey stanza`** : la clé n'a pas été touchée à temps
  (environ 15 secondes). Relancer la commande.
- GnuPG et PIV partagent la carte via pcscd
  ([gfriloux/stc#111](https://github.com/gfriloux/stc/issues/111)) : inutile
  d'arrêter `scdaemon` avant.

## La clé de secours

Une clé age simple, générée le 2026-10-25, rangée hors ligne et sur aucune
machine. Sa clé publique est
`age1faz4m9gj9xyz4rm26gndwgjkwrwr9ppnzm48slcrne7uvf3afqcsxtv8hs`.

Pour s'en servir, la mettre dans un fichier temporaire, y pointer sops, puis
détruire le fichier :

```bash
SOPS_AGE_KEY_FILE=/tmp/rescue.txt sops secrets/clochette.yaml
shred -u /tmp/rescue.txt
```

## Procédure de vérification

À faire quelques fois par an. La sortie part dans `/dev/null` : aucun secret
ne s'affiche.

```bash
# YubiKey : ouvre tous les fichiers (PIN, puis toucher pour chacun)
for f in kuri_exampleHost clochette RogueLeader; do
  SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt \
    sops -d secrets/$f.yaml > /dev/null && echo "$f OK"
done

# Clé de démarrage d'exampleHost : ouvre son fichier, et seulement celui-là
for f in kuri_exampleHost clochette RogueLeader; do
  SOPS_AGE_KEY_FILE=/etc/sops/age/keys.txt sops -d secrets/$f.yaml > /dev/null 2>&1 \
    && echo "$f : ouvert" || echo "$f : refusé"
done
# Attendu : kuri_exampleHost ouvert, clochette et RogueLeader refusés
```

Tester la clé de secours de la même façon, depuis sa copie hors ligne.

## Réinstaller exampleHost

La clé de démarrage n'est plus précieuse : une réinstallation en génère une
nouvelle.

1. La générer :

   ```bash
   sudo mkdir -p /etc/sops/age
   sudo age-keygen -o /etc/sops/age/keys.txt
   sudo chown root:users /etc/sops/age/keys.txt && sudo chmod 640 /etc/sops/age/keys.txt
   sudo age-keygen -y /etc/sops/age/keys.txt    # nouvelle clé publique
   ```

2. Dans `.sops.yaml`, remplacer `&desktop_examplehost` par la nouvelle clé
   publique.
3. Rechiffrer le fichier d'exampleHost avec la YubiKey :

   ```bash
   sops updatekeys secrets/kuri_exampleHost.yaml
   ```

4. Commiter `.sops.yaml` et le fichier, puis déployer : `just install`.

L'ancien `keys.txt`, s'il en reste une copie, n'ouvre plus rien une fois
`updatekeys` passé : la détruire.

## Réinstaller clochette ou RogueLeader

Une réinstallation génère une **nouvelle clé SSH host**, donc la clé age
dérivée change.

1. Récupérer la nouvelle clé publique, depuis la machine réinstallée :

   ```bash
   nix run nixpkgs#ssh-to-age -- -i /etc/ssh/ssh_host_ed25519_key.pub
   ```

2. Dans `.sops.yaml`, remplacer `&server_clochette` (ou `&server_rogueleader`).
3. Rechiffrer, depuis exampleHost, avec la YubiKey :

   ```bash
   sops updatekeys secrets/clochette.yaml
   ```

4. Commiter, puis déployer : `just install_clochette` (ou `just install_rogueleader`).

## Clés perdues

| Perdu | Conséquence | Remède |
|---|---|---|
| Clé de démarrage d'exampleHost | exampleHost ne déchiffre plus ses secrets au démarrage | Procédure de réinstallation ci-dessus, avec la YubiKey |
| Clé SSH host d'un serveur | Ce serveur ne déchiffre plus ses secrets | Procédure de réinstallation serveur ci-dessus |
| YubiKey | Plus d'édition avec elle | Prendre la clé de secours, enrôler une nouvelle YubiKey, `updatekeys` sur les trois fichiers, retirer l'ancien `&admin_yubikey` |
| Clé de secours | Plus de solution de repli si la YubiKey est perdue | En générer une nouvelle, `updatekeys` sur les trois fichiers avec la YubiKey |
| YubiKey **et** clé de secours | Plus aucune clé d'administration | Chaque fichier reste lisible sur sa propre machine avec sa clé : le rechiffrer depuis là vers de nouvelles clés d'administration |

:::danger[Interdit]
Perdre en même temps la YubiKey et la clé de secours ne laisse aucune clé qui ouvre tous les fichiers.
Garder la clé de secours hors ligne, loin de la YubiKey, et la tester.
:::
