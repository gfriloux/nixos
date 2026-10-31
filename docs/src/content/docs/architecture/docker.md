---
title: "Docker patterns"
description: "Docker patterns: health checks, networks, secrets, UIDs, startup order."
---

| Need | Pattern |
|---|---|
| Health check | `extraOptions = inputs.stc.lib.docker.mkHealthCheck { cmd = "..."; startPeriod = "30s"; };` (interval 30s, timeout 10s, 3 retries). Add the `stc.docker/health-watch` label for restart + alert: [Failure notifications](/nixos/operations/notifications/) |
| Published through the gateway | `networks = ["web"];` newt reaches the container by name |
| Internal only (databases) | its own network, e.g. `networks = ["immich"];` |
| Both | `networks = ["immich" "web"];` |
| Create a network | `inputs.stc.lib.docker.mkNetwork pkgs "<name>"` (systemd unit `docker-network-<name>`) |
| Secrets as env vars | `environmentFiles = [ config.sops.secrets."services/<name>/env".path ];` (plain `KEY=value`) |
| Rootless container | `users.users.<name>` / `users.groups.<name>` with fixed uid/gid in the same file, data dirs via `systemd.tmpfiles.rules` |
| Start after another container | `dependsOn = ["immich-postgres" "immich-redis"];` |
| Other systemd ordering | `systemd.services."docker-<name>"` (e.g. `web` network before newt in `docker-newt.nix`) |
