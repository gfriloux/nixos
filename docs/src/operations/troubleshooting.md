# Dépannage

Problèmes courants et procédures de diagnostic.

---

## Un container est en état `unhealthy`

```bash
# Voir les derniers résultats du health check
docker inspect --format='{{json .State.Health}}' <nom-container> | jq

# Voir les logs du container
docker logs <nom-container> --tail 50

# Redémarrer manuellement
systemctl restart docker-<nom-container>
```

Le timer `docker-health-watch@<nom>` tue automatiquement un container `unhealthy`
toutes les 30 secondes, ce qui déclenche un restart systemd.
Si le container reste en boucle, vérifier ses logs.

---

## Un service systemd est en `failed`

```bash
# Voir le statut et les logs
systemctl status docker-<nom>
journalctl -u docker-<nom> --since "30 minutes ago"

# Réinitialiser le compteur d'échecs avant de redémarrer
systemctl reset-failed docker-<nom>
systemctl start docker-<nom>
```

---

## Traefik ne répond plus

```bash
# Health check interne
docker exec traefik traefik healthcheck

# Vérifier que le container tourne
docker ps | grep traefik

# Vérifier les certificats Let's Encrypt
ls -lh /srv/docker/traefik/acme.json
# Si 0 octets : les certs n'ont pas été générés
# Let's Encrypt a une limite de 5 tentatives / domaine / heure

# Logs Traefik
tail -100 /srv/docker/traefik/logs/traefik.log | jq .
```

---

## sops ne peut pas déchiffrer les secrets

```bash
# Vérifier que la clé age est présente
ls -la /etc/sops/age/keys.txt

# Vérifier la clé publique
age-keygen -y /etc/sops/age/keys.txt
# Doit correspondre à celle dans .sops.yaml

# Test de déchiffrement
sops -d secrets/clochette.yaml
```

Si la clé publique ne correspond pas : voir [Sauvegarde & restauration des secrets](secrets-backup.md).

---

## Déploiement nixos-rebuild échoue

```bash
# Construire sans déployer pour voir l'erreur
just build_clochette

# Vérifier les linters
just test

# Vérifier l'évaluation du flake
nix flake check
```

Si l'erreur est réseau (timeout lors du téléchargement), relancer.
Si c'est une erreur d'évaluation Nix, lire le message d'erreur complet :
les erreurs sops ou de type manquant sont souvent explicites.

---

## SSH vers clochette inaccessible

Ordre de vérification :

1. Tailscale est-il actif sur les deux machines ?
   ```bash
   tailscale status  # depuis exampleHost
   ```

2. clochette est-elle joignable via ping Tailscale ?
   ```bash
   tailscale ping clochette
   ```

3. Le démon SSH tourne-t-il sur clochette ?
   Utiliser la console série Scaleway pour vérifier :
   ```bash
   systemctl status sshd
   ```

4. La règle firewall est-elle en place ?
   ```bash
   sudo nft list ruleset | grep 100.64
   ```

---

## Docker storage driver ZFS (exampleHost)

Si Docker ne démarre pas sur exampleHost avec une erreur ZFS :

```bash
# Vérifier que le dataset Docker existe
zfs list | grep docker

# Docker utilise rpool/nixos/var/lib comme base
# Le dataset docker est dans /var/lib/docker
docker info | grep "Storage Driver"

# Si Docker a laissé un état corrompu
sudo systemctl stop docker
sudo rm -rf /var/lib/docker/devicemapper  # ou le sous-dossier problématique
sudo systemctl start docker
```

---

## Borg backup échoue

```bash
# Dernier statut
journalctl -u borgbackup-job-remote --since today

# Tester la connexion SSH vers le serveur de backup
ssh -i /run/secrets/services/borg/key/private backup@storage2.friloux.me

# Tester l'accès au dépôt
BORG_PASSPHRASE=$(cat /run/secrets/services/borg/passphrase) \
BORG_RSH="ssh -i /run/secrets/services/borg/key/private" \
borg info ssh://backup@storage2.friloux.me/~/clochette.friloux.me
```

Causes fréquentes :
- Clé SSH du serveur de backup changée → mettre à jour `backup.nix` `knownHostsFiles`
- Espace disque plein sur le serveur de backup
- Verrou Borg bloqué : `borg break-lock ssh://backup@storage2.friloux.me/~/clochette.friloux.me`

---

## ZFS pool dégradé (exampleHost)

```bash
# État des pools
zpool status

# Si un disque est DEGRADED / FAULTED
zpool status -v  # détail des erreurs

# Après remplacement physique d'un disque
zpool replace rpool /dev/disk/by-id/ANCIEN_ID /dev/disk/by-id/NOUVEAU_ID
# Suivre la résilver
zpool status -w rpool
```

---

## Préemptions WeeCHAT / session zellij perdue

```bash
# Se connecter à la session weechat existante
ssh irc.friloux.me
# Dans le shell weechat :
zellij attach
```

Si la session zellij n'existe plus :

```bash
zellij  # crée une nouvelle session
# Puis relancer weechat manuellement
weechat
```
