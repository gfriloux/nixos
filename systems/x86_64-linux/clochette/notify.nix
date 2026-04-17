{
  pkgs,
  config,
  lib,
  ...
}: let
  notifyScript = pkgs.writeShellScript "notify-failure" ''
    SERVICE="$1"
    NTFY_TOPIC=$(cat ${config.sops.secrets."services/ntfy/topic".path})

    ${pkgs.curl}/bin/curl -s \
      -H "Title: [clochette] $SERVICE en défaut" \
      -d "$SERVICE est passé en état failed" \
      "https://ntfy.sh/$NTFY_TOPIC"
  '';

  healthWatchScript = pkgs.writeShellScript "docker-health-watch" ''
    CONTAINER="$1"
    STATUS=$(${pkgs.docker}/bin/docker inspect --format='{{.State.Health.Status}}' "$CONTAINER" 2>/dev/null)
    if [ "$STATUS" = "unhealthy" ]; then
      ${pkgs.docker}/bin/docker kill "$CONTAINER"
    fi
  '';

  watched =
    lib.filterAttrs (
      _: c:
        (c.labels or {}) ? "friloux.me/health-watch"
    )
    config.virtualisation.oci-containers.containers;
in {
  sops.secrets."services/ntfy/topic" = {};

  systemd = {
    services = {
      "notify-failure@" = {
        description = "Notification d'échec du service %i";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${notifyScript} %i";
        };
      };
      "docker-health-watch@" = {
        description = "Surveillance santé Docker du conteneur %i";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${healthWatchScript} %i";
        };
      };
    };

    timers =
      lib.mapAttrs' (name: _: {
        name = "docker-health-watch@${name}";
        value = {
          description = "Timer de surveillance santé Docker pour ${name}";
          wantedBy = ["timers.target"];
          partOf = ["${name}.service"];
          timerConfig = {
            OnBootSec = "240s";
            OnUnitActiveSec = "30s";
            Unit = "docker-health-watch@${name}.service";
          };
        };
      })
      watched;
  };
}
