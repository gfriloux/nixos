---
title: Bound Daemons — Common Patterns
description: Health checks, Docker networks, secrets, UIDs, and startup dependencies.
---

All bound daemons on clochette follow sacred patterns for health, networking, secrets, and startup order.

## Health Checks

All monitored containers declare a health check via `extraOptions`:

```nix
extraOptions = lib.kuri.docker.mkHealthCheck {
  cmd = "command-to-test";
  startPeriod = "30s";  # delay before first check (default: 0)
};
```

`mkHealthCheck` generates the flags `--health-cmd`, `--health-interval=30s`,
`--health-timeout=10s`, `--health-retries=3`.

## Docker Networks

Containers exposed via Traefik join the `web` network.
Containers for internal use (databases) have their own isolated network.

```nix
networks = ["web"];          # exposed to Traefik
networks = ["immich"];       # internal only
networks = ["immich" "web"]; # internal + Traefik
```

Networks are created by systemd services `docker-network-<name>`
generated via `lib.kuri.docker.mkNetwork`.

## Secrets

Sensitive environment variables are passed via sops `environmentFiles`:

```nix
environmentFiles = [
  config.sops.secrets."services/<name>/env".path
];
```

The `env` file contains plain `KEY=value` pairs (decrypted by sops-nix).

## UIDs & GIDs

Rootless containers have a dedicated system user declared in the same file:

```nix
users.users.immich-postgres = { uid = 999; isSystemUser = true; group = "immich-postgres"; ... };
users.groups.immich-postgres = { gid = 999; };
```

Data directories are created with correct ownership via `systemd.tmpfiles.rules`.

## Startup Order

Inter-container dependencies are declared with `dependsOn`:

```nix
"immich-server" = {
  dependsOn = ["immich-postgres" "immich-redis"];
  ...
};
```

Additional systemd dependencies (e.g., CrowdSec → Traefik) are
declared in `systemd.services."docker-<name>"`.
