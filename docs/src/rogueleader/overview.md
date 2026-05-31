# rogueleader — serveur dédié

Serveur dédié domestique hébergeant des services internes.

## Configuration actuelle

| Paramètre | Valeur |
|---|---|
| Rôle | Serveur domestique interne |
| Accès réseau local | `rogueleader.home` (192.168.0.10) |
| OS | NixOS 25.11 |
| Disque | `/dev/sda`, ext4, GPT (via disko) |
| sops | Clé age dérivée du SSH host key |
| stateVersion | `25.11` |

## Services Docker actifs

| Container | Rôle |
|---|---|
| `borg-ui` | Interface web Borg backup |
| `mealie` | Gestionnaire de recettes |
| `uptime-kuma` | Monitoring de disponibilité externe |

## Backup

Configuré avec borgbackup vers `storage2.friloux.me` (même pattern que clochette).

## Notes importantes

- sops dérive la clé age depuis `/etc/ssh/ssh_host_ed25519_key` (comme clochette)
- Après réinstallation : mettre à jour `.sops.yaml` avec la nouvelle clé age publique
  (voir [Sauvegarde & restauration des secrets](../operations/secrets-backup.md))
- Déploiement depuis exampleHost : `just install_rogueleader`
- Home Manager : `just home_rogueleader`
