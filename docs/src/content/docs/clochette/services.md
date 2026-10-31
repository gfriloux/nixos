---
title: Bound Daemons — Common Patterns
description: Health checks, Docker networks, secrets, UIDs, and startup dependencies.
---

All bound daemons on clochette follow sacred patterns for health, networking, secrets, and startup order.

## Health Checks

All monitored containers declare a health check via `extraOptions`:

```nix
extraOptions = inputs.stc.lib.docker.mkHealthCheck {
  cmd = "command-to-test";
  startPeriod = "30s";  # grace period before failures count (default: 30s)
};
```

`mkHealthCheck` (from the STC flake input) generates the flags `--health-cmd`,
`--health-interval=30s`, `--health-timeout=10s`, `--health-start-period`,
`--health-retries=3`. Pair it with the `stc.docker/health-watch` label to get
restarts and notifications (see [The Astropath](notifications.md)).

## Docker Networks

Containers published through the pangolin gateway join the `web` network,
where `newt` reaches them by name (see [The Gate](../skitarii/gateway.md)).
Containers for internal use (databases) have their own isolated network.

```nix
networks = ["web"];          # reachable by newt
networks = ["immich"];       # internal only
networks = ["immich" "web"]; # internal + newt
```

Networks are created by systemd services `docker-network-<name>`
generated via `inputs.stc.lib.docker.mkNetwork pkgs "<name>"`.

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

Additional systemd dependencies (e.g., the `web` network before newt and
immich-server, in `docker-newt.nix`) are
declared in `systemd.services."docker-<name>"`.
