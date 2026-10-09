{
  pkgs,
  config,
  ...
}: {
  users = {
    mutableUsers = false;
    users.guillaume = {
      createHome = true;
      isNormalUser = true;
      home = "/home/guillaume";
      description = "Moi";
      extraGroups = ["wheel"];
      hashedPasswordFile = config.sops.secrets."users/guillaume/hashed-password".path;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIETPEOCEETy3EHFswjsoEsMmu4i7TUPCXwPrhVsjH8rE guillaume+perso@friloux.me"
        "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAINzSEYfdMZ004bSYJ0/quBO1g5+SG5mnqf8SWuFlTnuWAAAAD3NzaDpyb2d1ZWxlYWRlcg== guillaume@rogueleader.friloux.me"
      ];
      shell = pkgs.fish;
    };

    # Compte dédié et restreint pour les audits Nix automatisés (Hermes Agent).
    # Clé publique uniquement, pas de mot de passe, pas de groupe privilégié.
    # Contexte : https://github.com/gfriloux/nixos/issues/70
    users.hermes-audit = {
      createHome = true;
      isNormalUser = true;
      home = "/home/hermes-audit";
      description = "Hermes Agent — audits Nix automatisés (lecture/build seulement)";
      extraGroups = [];
      hashedPassword = "!"; # login par mot de passe explicitement désactivé
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOYskA7bsGIgqPo3ef5Z+6HC3jfn4AZ2gISEnasWvTqr hermes-agent-audit@friloux.me"
      ];
      shell = pkgs.bash;
    };
  };
}
