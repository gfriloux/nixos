{config, ...}: {
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
  # (mealie:9000), sans passer par le traefik local.
  virtualisation.oci-containers.containers.newt = {
    image = "docker.io/fosrl/newt:1.19.1"; # renovate
    environmentFiles = [config.sops.templates."newt.env".path];
    networks = ["web"];
  };
}
