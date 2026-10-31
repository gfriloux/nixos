{
  config,
  inputs,
  ...
}: {
  sops = {
    secrets = {
      "services/newt/id" = {};
      "services/newt/secret" = {};
    };
    templates."newt.env".content = ''
      PANGOLIN_ENDPOINT=https://pangolin.friloux.me
      NEWT_ID=${config.sops.placeholder."services/newt/id"}
      NEWT_SECRET=${config.sops.placeholder."services/newt/secret"}
    '';
  };

  # Tunnel sortant vers la passerelle pangolin de skitarii : rien n'est publié
  # ici. Sur le réseau web, newt joint les conteneurs par leur nom
  # (immich-server:2283), sans passer par le traefik local.
  virtualisation.oci-containers.containers.newt = {
    image = "docker.io/fosrl/newt:1.19.1"; # renovate
    environmentFiles = [config.sops.templates."newt.env".path];
    # Écrit quand le ping vers la passerelle passe, supprimé quand le tunnel
    # tombe : le healthcheck suit l'état du tunnel, pas seulement le process.
    environment.HEALTH_FILE = "/tmp/healthy";
    networks = ["web"];
    extraOptions = inputs.stc.lib.docker.mkHealthCheck {
      cmd = "test -f /tmp/healthy";
      startPeriod = "30s";
    };
    labels."stc.docker/health-watch" = "true";
  };
}
