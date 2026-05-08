{
  config,
  pkgs,
  lib,
  ...
}: let
  images =
    lib.mapAttrsToList (_: c: c.image)
    config.virtualisation.oci-containers.containers;
in {
  system.activationScripts.dockerPrePull =
    lib.concatMapStringsSep "\n" (image: ''
      echo "pre-pull: ${image}" >&2
      ${pkgs.docker}/bin/docker pull "${image}" 2>&1 || true
    '')
    images;
}
