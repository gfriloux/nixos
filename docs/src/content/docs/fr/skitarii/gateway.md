---
title: La Porte — Pangolin, Gerbil, Traefik & CrowdSec
description: Comment la passerelle pangolin de skitarii est câblée, ce qui vit où, et les pièges déjà rencontrés.
---

Le sanctuaire-porte fait tourner la pile pangolin, sauvegardée chaque nuit
sur storage2, avec healthchecks et notifications ntfy sur chaque conteneur.

## Architecture

```text
Internet (IPv4 + IPv6)
    │
    └── gerbil  ── publie 80/443 TCP, 443/51820/21820 UDP
          │        (WireGuard pour les tunnels newt)
          └── traefik  (vit dans l'espace réseau de gerbil)
                ├── entrypoints web + websecure → crowdsec@file (bouncer)
                ├── fournisseur fichier → pangolin.friloux.me (dashboard + API)
                └── fournisseur HTTP    → http://pangolin:3001/api/v1/traefik-config
                                          (chaque ressource créée dans pangolin)

réseau docker "pangolin" (IPv4 + fd49:e7d1:9e38::/64)
    pangolin · gerbil (+ traefik) · crowdsec · crowdsec-manager
```

| Conteneur | Image | Rôle |
|---|---|---|
| `pangolin` | `fosrl/pangolin:ee-*` | Dashboard et API, SQLite dans `/srv/docker/pangolin.friloux.me/config`. Édition Enterprise, licence gratuite pour usage personnel saisie dans `/admin/license` |
| `gerbil` | `fosrl/gerbil` | Point d'entrée WireGuard, porte les ports publiés |
| `traefik` | `traefik` | Reverse proxy, Let's Encrypt (HTTP-01), plugins badger + bouncer crowdsec |
| `crowdsec` | `crowdsecurity/crowdsec` | Relic STC, lit le log d'accès de traefik |
| `crowdsec-manager` | `hhftechnology/crowdsec-manager` | UI CrowdSec, socket Docker brut |

Tout est dans `systems/x86_64-linux/skitarii/docker-pangolin.nix` et
`docker-crowdsec-manager.nix` ; la relic crowdsec est réglée dans `default.nix`.

## D'où Vient la Configuration

| Source | Contenu | Écrit par |
|---|---|---|
| Fournisseur HTTP de traefik | Chaque ressource, route, règle d'auth créée dans le dashboard | pangolin, en direct, depuis sa base |
| `dynamic_config.yml` de traefik | Routes du dashboard et middlewares `badger`, `crowdsec`, `redirect-to-https` | Nix (lecture seule, depuis le store) |
| `traefik_config.yml` | Entrypoints, plugins, ACME, log d'accès | Nix (lecture seule, depuis le store) |
| `config.yml` de pangolin | URL du dashboard, domaine de base `friloux.me`, flags | Template sops (porte `server.secret`) |

Tout ce qui se configure dans pangolin fonctionne. Seule la fonction de
crowdsec-manager qui édite les fichiers de traefik ne marche pas : ces
changements passent par Nix.

## Secrets

Dans `secrets/skitarii.yaml` :

- `services/pangolin/secret` — le `server.secret` de pangolin
- `services/crowdsec/bouncer-key` — crowdsec l'enregistre au démarrage
  (`BOUNCER_KEY_traefik`), traefik la lit dans un fichier monté

## Publier un Service

1. CNAME `<nom>` → `skitarii.friloux.me.` chez Gandi, **avant** que quoi que
   ce soit n'interroge ce nom (un `NXDOMAIN` en cache dure 3 heures).
2. Dans pangolin : une ressource sur le bon site. **Local** pour un conteneur
   du réseau `pangolin` de skitarii ; un tunnel newt pour une autre machine.
3. Laisser le SSO actif, sauf si le service doit être public. Enregistrer
   l'onglet d'authentification : désactiver le SSO sans enregistrer le
   laisse actif, et le navigateur, qui a déjà une session sur le dashboard,
   le masque (`401` avec `curl`, page normale dans le navigateur).

## Ajouter un Site newt

Une machine rejoint la passerelle par un tunnel newt sortant : rien n'est
publié chez elle, pas de redirection de port. Le premier : RogueLeader
(`docker-newt.nix`), qui sert `cuisine.friloux.me` (mealie). Puis clochette,
qui sert `photos.friloux.me` (immich).

Si aucun traefik local n'a créé le réseau `web`, la machine doit le créer
elle-même : le `docker-newt.nix` de clochette le fait avec
`stc.lib.docker.mkNetwork`.

1. Dans pangolin : **Sites** → **Add Site**, type **Newt**. Noter l'id et le
   secret, affichés une seule fois.
2. Les mettre dans le fichier sops de la machine, en `services/newt/id` et
   `services/newt/secret`.
3. Lancer newt en conteneur sur le réseau des services qu'il sert (`web` sur
   RogueLeader). Reprendre le `docker-newt.nix` de RogueLeader : un template
   sops rend `PANGOLIN_ENDPOINT`, `NEWT_ID`, `NEWT_SECRET`.
4. Déployer : `docker logs newt` doit afficher `Tunnel connection to server
   established successfully!` et le site passe **Online**.
5. Les cibles des ressources utilisent le nom du conteneur et son port
   interne (`http://mealie:9000`).

Le trafic tunnelé entre quand même par le traefik de skitarii : le bouncer
voit la vraie adresse du visiteur et les bans s'appliquent (vérifié par un
ban manuel).

`photos.friloux.me` n'a pas de SSO pangolin : l'application mobile Immich ne
passerait pas. Immich ne limite pas lui-même les connexions ; le scénario
`LePresidente/http-generic-401-bf` bannit les rafales de `POST` répondues en
401.

## crowdsec-manager

Publié comme ressource pangolin `crowdsec.friloux.me` (site local, cible
`http://crowdsec-manager:8080`), derrière le SSO pangolin **et le TOTP**. Il a
le socket Docker brut : l'atteindre, c'est root sur skitarii.

:::caution[Garde]
Les clés de sécurité de pangolin servent à se connecter, pas de second
facteur. Seul un TOTP activé fait demander un code après le mot de passe.
Vérifier en navigation privée, sans session ouverte sur le dashboard.
:::

## Vérifications

```bash
# Bouncer enregistré, log d'accès lu
sudo docker exec crowdsec cscli bouncers list
sudo docker exec crowdsec cscli metrics show acquisition

# L'adresse vue par traefik (celle du visiteur, IPv4 ou IPv6)
sudo tail -n 3 /srv/docker/pangolin.friloux.me/traefik-logs/access.log \
  | nix run nixpkgs#jq -- -r '[.ClientHost, .RouterName, .DownstreamStatus] | @tsv'

# Test de ban de bout en bout (5 min), attendre 70 s avant de tester
sudo docker exec crowdsec cscli decisions add --ip <IP> --duration 5m --reason test
```

## Sauvegarde, Santé et Alertes

| Quoi | Où | Détail |
|---|---|---|
| Sauvegarde Borg | `backup.nix` | 04:00 vers `storage2.friloux.me/~/skitarii.friloux.me`, `borg check` chaque semaine. Restauration : [Restauration des Données depuis Borg](../operations/restore.md) |
| Copies SQLite | `/srv/docker/sqlite-snapshots` | pangolin, crowdsec, crowdsec-manager (settings, history), faites par le job avant `borg create` |
| Rotation des logs | `docker-pangolin.nix` | `access.log` chaque jour, 14 gardés, renommage puis `USR1` |
| Healthchecks | `docker-pangolin.nix` | pangolin `:3001/api/v1/`, gerbil `:3004/healthz`, `traefik healthcheck` ; crowdsec et crowdsec-manager ont le leur |
| Notifications | `default.nix` | `stc.relics.docker.notify`, topic ntfy dans `secrets/skitarii.yaml` |
| Alertes sites et ressources | UI pangolin (base de données, sauvegardée) | Règles d'alerte *site toggle* et *resource toggle*, webhook vers ntfy (ci-dessous) |

### Alertes pangolin vers ntfy

Deux règles d'alerte dans le dashboard, chacune avec une action webhook : URL
`https://ntfy.sh/` (la racine : ntfy n'y lit un corps JSON que là), méthode
`POST`, body template actif, le topic dans le corps :

```json
{"topic":"TOPIC","title":"[pangolin] site {{siteName}} {{status}}","message":"{{event}} à {{timestamp}}"}
```

La règle des ressources utilise `{{resourceName}}` au lieu de
`site {{siteName}}`. Les événements de ressource ne partent que pour les
cibles qui ont un health check.

## Pièges Déjà Rencontrés

- **badger v1.8.0** échoue au contrôle d'intégrité des plugins traefik, qui
  désactive alors *tous* les plugins : toutes les routes du dashboard
  tombent sur `invalid middleware "badger@file"`. Figé en v1.7.0
  (traefik/traefik#14115).
- **Le test de ban renvoie 200** : en mode `live`, le bouncer garde une IP
  propre en cache 60 secondes. Attendre avant de conclure.
- **Visiteurs IPv6 vus avec une adresse privée** : sans IPv6 sur le réseau
  Docker, les ports publiés passent par `docker-proxy` et traefik voit la
  passerelle Docker, que crowdsec ignore. Le réseau a maintenant un /64 ULA ;
  changer ses options demande d'arrêter les conteneurs et
  `docker network rm pangolin`, le script de création ne recrée jamais un
  réseau existant.
- **Pas de notification ntfy, pas d'erreur** : ntfy.sh limite l'IPv6 par /64,
  et celui de skitarii est partagé entre VPS OVH ; son quota anonyme est
  épuisé par les voisins (`429`). Chaque appel ntfy ici passe par `curl -4`,
  et `--fail` pour qu'un `429` fasse échouer l'unité au lieu de sortir en 0.
- **`{{resourceName}}` non remplacé dans une alerte de test** : le bouton
  *Test* du dashboard envoie de fausses données (`siteName: "Test Resource
  Alert"`, statut aléatoire). Les vraies alertes portent le nom de la
  ressource.
- **Erreurs au démarrage** (`connection refused` sur `pangolin:3001`,
  `no such host crowdsec`, `crowdsec@file does not exist` sur les routeurs
  internes) : elles cessent quelques secondes après un redémarrage. Si elles
  durent, elles sont réelles.

## Pas Encore Fait

- AppSec (inspection des requêtes) dans crowdsec
