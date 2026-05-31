# CrowdSec

WAF et protection DDoS intégré à Traefik via plugin bouncer.

## Fonctionnement

CrowdSec analyse les logs Traefik (`/srv/docker/traefik/logs/traefik.log`)
et alimente une liste de décisions (bans, captcha). Le plugin Traefik
`crowdsec-bouncer-traefik-plugin` consulte CrowdSec en temps réel pour bloquer les IPs.

`crowdsec-manager` fournit une UI web de gestion accessible sur le port 3000 (interne).

## Health check

```bash
curl -s http://localhost:8080/health
# ou
docker exec crowdsec wget -q -O /dev/null http://localhost:8080/health
```

## Commandes cscli utiles

```bash
# Entrer dans le container CrowdSec
docker exec -it crowdsec sh

# Lister les décisions actives (bans)
cscli decisions list

# Bannir manuellement une IP
cscli decisions add --ip 1.2.3.4 --duration 24h --reason "test manuel"

# Lever un ban
cscli decisions delete --ip 1.2.3.4

# Voir les alertes récentes
cscli alerts list

# Statut des collections installées
cscli collections list
```

## Données persistantes

```
/srv/docker/crowdsec.clochette.friloux.me/
├── data/    # Base de données SQLite, GeoIP
└── etc/     # Configuration, parseurs, scénarios, décisions
```

Ces répertoires sont inclus dans le backup Borg.

## Dépendance avec Traefik

Traefik requiert CrowdSec au démarrage :

```nix
systemd.services.traefik = {
  after = ["crowdsec.service"];
  requires = ["crowdsec.service"];
};
```

Si CrowdSec ne démarre pas, arrêter cette dépendance temporairement
pour diagnostiquer sans bloquer Traefik :

```bash
systemctl edit docker-traefik
# Ajouter [Unit] et supprimer After/Requires liés à crowdsec
# Attention : temporaire seulement, revenir à la config Nix ensuite
```
