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
  };
}
