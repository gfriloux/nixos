# NixOS Flake — Context

## Structure

Snowfall-lib flake with four systems:

- `clochette` — VPS (Scaleway), Docker-based services behind Traefik
- `exampleHost` — desktop workstation (ZFS mirror, AMD GPU, Plasma 6)
- `RogueLeader` — local dedicated server, Docker-based services
- `skitarii` — VPS (OVH VPS-1), future pangolin gateway; base system only for now

Two homes on clochette: `guillaume` (admin), `weechat` (IRC session via zellij).

Secrets managed with sops-nix + age encryption:

- `secrets/clochette.yaml` — encrypted with clochette key + admin keys
- `secrets/kuri_exampleHost.yaml` — encrypted with exampleHost key + admin keys
- `secrets/RogueLeader.yaml` — encrypted with RogueLeader key + admin keys
- `secrets/skitarii.yaml` — encrypted with skitarii key + admin keys

Admin keys (editing only, never at boot): an age identity on the YubiKey (PIV slot 1, needs `age-plugin-yubikey`, PIV PIN ≠ GPG PIN) and an offline rescue key. No host key may be a recipient of another host's file (#94).

Age key locations:

- exampleHost: `/etc/sops/age/keys.txt` (manually placed, opens `kuri_exampleHost.yaml` only)
- clochette: derived from `/etc/ssh/ssh_host_ed25519_key` (no explicit keyFile)
- RogueLeader: derived from `/etc/ssh/ssh_host_ed25519_key` (via `age.sshKeyPaths`)
- skitarii: same as RogueLeader; the host key is generated on exampleHost before install and passed with `nixos-anywhere --extra-files`

## Documentation

Project documentation lives in `docs/` — **Astro + Starlight**, bilingual EN/FR, deployed to GitHub Pages at `https://gfriloux.github.io/nixos/`.

```text
just docs-install   # npm install
just docs-dev       # dev server (localhost:4321/nixos/)
just docs-build     # production build → docs/dist/
just docs-preview   # serve the built dist
```

`nodejs` is in the Nix devShell (`shells/default/default.nix`) so `npm` is available inside `nix develop`.

**Content structure**: English pages at `docs/src/content/docs/`, French at `docs/src/content/docs/fr/`. Starlight i18n uses `defaultLocale: 'root'` (EN at `/nixos/`, FR at `/nixos/fr/`).

**Key config invariants** (`docs/astro.config.mjs`):

- `base` is extracted as a `const` at the top and reused everywhere — including the `grimoire-fx.js` script src (`${base}/grimoire-fx.js`) and hero action links in `index.mdx` (`/nixos/introduction/`). Starlight does NOT auto-prefix absolute paths with the base.
- Starlight 0.39+ requires `autogenerate` to be wrapped in `items`: `items: [{ autogenerate: { directory: '...' } }]`.
- Content config lives at `src/content.config.ts` (Astro v6 — the old `src/content/config.ts` location is gone).
- Custom `Header.astro` component moves the search bar into the right group (next to ThemeSelect/LanguageSelect) — the default Starlight header centers it.

**CI**: `.github/workflows/docs.yml` — triggers on push to `main` when `docs/**` changes, builds with Node 22, deploys to GitHub Pages via `actions/upload-pages-artifact` + `actions/deploy-pages`.

Covers: reinstallation procedures (all 4 machines), secrets backup/restore, Tailscale re-enrollment, deployment reference, per-service guides, troubleshooting.

## Docker services

clochette and RogueLeader run traefik, crowdsec and socket-proxy from STC's
docker relics (`stc.relics.docker.*`, configured in each host's `default.nix`).
skitarii runs only the crowdsec relic, wired to its local traefik in
`docker-pangolin.nix`. On top of that:

| Host | Containers | Role |
|---|---|---|
| clochette | immich-server, immich-postgres, immich-redis | Photo gallery (photos.friloux.me) |
| clochette | crowdsec-manager | CrowdSec web UI, Tailscale-only; keeps the raw Docker socket (needs POST) |
| skitarii | pangolin, gerbil, traefik | Gateway (pangolin.friloux.me); local traefik in gerbil's netns, not STC's relic |
| skitarii | crowdsec-manager | CrowdSec web UI, published as a pangolin resource (crowdsec.friloux.me) behind pangolin SSO + 2FA; raw Docker socket |
| RogueLeader | wow-cp-bookstack, wow-cp-mariadb, wow-cp-mysqldump | Wiki (wow-cp.friloux.me) and its nightly DB dump |
| RogueLeader | uptime-kuma | Status page (status.friloux.me) |
| RogueLeader | papra | Documents (docs.friloux.me) |
| RogueLeader | mealie | Recipes (cuisine.home.friloux.me) |
| RogueLeader | borg-ui, borg-redis | Borg web UI (borg-ui.friloux.me) |

## Key patterns

**Secrets**: always declare near the service that uses them (in `docker-*.nix`), not in `default.nix` — except the secrets fed to STC's docker relics, declared in `default.nix` next to `stc.relics.docker`. Use `config.sops.secrets.<name>.path` to reference paths — never hardcode `/run/secrets/...`. For user passwords, use `neededForUsers = true` which puts secrets in `/run/secrets-for-users/`.

**Static config files**: use `systemd.tmpfiles.rules` with `L+` (symlink to Nix store) — never `C` (copy), which doesn't update on rebuild.

**UIDs/GIDs**: declared once in `users.users.<name>.uid` / `users.groups.<name>.gid`. Container `user` field reads from `config.users.users.<name>.uid`. `tmpfiles` rules use the username string directly.

**Docker healthchecks**: `extraOptions = inputs.stc.lib.docker.mkHealthCheck { ... }`, since the NixOS oci-containers module has no native healthcheck option. `--health-on-fail` does NOT exist in `docker run` — it is Docker Compose only.

**Container failure notifications**: handled by STC's `relics-docker-notify` (`stc.relics.docker.notify`, with the ntfy call in each host's `notifyCommand`). It defines two systemd templates:

- `stc-notify-failure@` — runs `notifyCommand` when a unit enters `failed` state (also usable as `OnFailure` for non-Docker units, e.g. the borg check)
- `stc-docker-health-watch@` + matching timer — polls `docker inspect` every 30s and does `docker kill <container>` if status is `unhealthy`, which propagates the failure to systemd

Each monitored container only needs the label `"stc.docker/health-watch" = "true"` — the relic generates its health-watch timer and its `systemd.services` restart/notification block (`OnFailure`, `StartLimitBurst`, `Restart = "on-failure"`). Do NOT declare these manually in `docker-*.nix`. Place this label last, after any traefik labels. The label is useless on a container without a healthcheck.

Container-specific `systemd.services` overrides (e.g. `after`/`requires` dependencies) can still be declared in `docker-*.nix` — NixOS will merge them with the generated block.

**Log rotation**: Traefik's access log is rotated by STC's traefik relic (rename + `USR1`). For anything else, `services.logrotate.settings.<name>`.

**Users**: `users.mutableUsers = false` on all systems — fully declarative, NixOS owns `/etc/shadow`.

**exampleHost sops-nix**: age key at `/etc/sops/age/keys.txt` (manually copied, lives on the root ZFS dataset). Secrets file: `secrets/kuri_exampleHost.yaml`, encrypted with the desktop age key + admin keys. Do not store boot-time keys under `/home` or `/var/lib` — both are ZFS datasets mounted late in the boot process.

**RogueLeader sops-nix**: age key derived from SSH host key (`age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"]`). After reinstall, the SSH host key changes → update `.sops.yaml` and run `sops updatekeys secrets/RogueLeader.yaml` from exampleHost.

**Simplification principle**: for single-machine configurations, avoid `mkOption`/`cfg.*` abstraction layers — use direct NixOS options instead. Abstraction only makes sense when multiple machines share the same module with different values.

## Deployment

```text
just install             # exampleHost (local, nh os switch)
just install_clochette   # requires --ask-sudo-password
just install_rogueleader # requires --ask-sudo-password
just home_rogueleader    # Home Manager only for RogueLeader
just install_skitarii    # through the tailnet, ssh block pins the key
```

The deploy user is `guillaume` via SSH. Always keep a root shell open before applying changes that touch sudo or user config.

clochette and skitarii SSH are accessible **only via Tailscale** (`100.64.0.0/10`). skitarii is installed from the OVH rescue (disk is `sdb` there, `sda` in normal boot) — see `docs/src/content/docs/operations/reinstall-skitarii.md`. RogueLeader is accessible on the local network (`192.168.0.10`).

## Preferences

- Work on one container / one change at a time, wait for explicit validation before moving on.
- Do not factor out repeated label patterns into helper functions — explicit repetition is preferred for readability.
- `nix flake check` runs STC's **purity seals** (`stc.lib.puritySeals.<system>`), one per `checks/` subdir: `nix` (deadnix + statix + alejandra), `gitleaks` (secret scan, allowlist in `.gitleaks.toml`), `markdown` (rumdl, `-d MD013,MD033`). Do not re-add per-tool `checks/` dirs — the `nix` seal already bundles the three linters. STC must be recent enough to expose `puritySeals` (it replaced the old `nix-checks` input). The pre-commit hook keeps its own local nix linters (generated in `shells/default/default.nix`) as a fast pre-commit gate.
- The `weechat` user has a shell (fish) and SSH access intentionally — it's used to attach to a persistent zellij/weechat IRC session.

## Deliberate omissions

Things that are absent on purpose. Each was evaluated, often tried, and
rejected for a cost that was measured. Do not "fix" one of them without
reading its row first. When something is removed after being tried, add a
row.

| Absent | Why | Cost if reintroduced |
|---|---|---|
| `virtualisation.docker.autoPrune` | Its weekly timer is `Persistent`, so it catches up at boot, before the containers have joined their networks (`ef217e6`) | Networks deleted, every container fails with "network not found" |
| `services.borgbackup.jobs.*.prune.keep` | storage2 prunes the repositories itself | A compromised client could rewrite its backup history through prune |
| A host key as recipient of another host's sops file | Each host key opens its own file only; admin keys are the YubiKey and the offline rescue key (#94) | One key on one disk opens every host's secrets again |
| Secrets in GitHub Actions | `check.yml` runs on `pull_request` only, with `contents: read` | A pull request could exfiltrate them |
| Outbound SMTP (465, 587) on clochette | Blocked by Scaleway; direct Gmail sending does not work. ntfy.sh over HTTPS is the only notification channel | Mails silently never leave |
| crowdsec-manager on a public route (clochette) | Tailscale-only there. On skitarii it is published, but only as a pangolin resource behind SSO + 2FA — never a bare traefik route or a published port | The WAF admin UI, and through the raw socket root on the host, exposed to the internet |

Not an omission but a deliberate choice that looks like one:
`neededForBoot = true` on every ZFS dataset, `/home` included, on exampleHost.
Uniformity was preferred over the strict minimum.
