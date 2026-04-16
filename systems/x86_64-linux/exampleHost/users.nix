{
  pkgs,
  config,
  ...
}: {
  users = {
    mutableUsers = false;
    users.kuri = {
      isNormalUser = true;
      extraGroups = ["users" "networkmanager" "video" "audio" "docker" "wheel" "disk"];
      shell = pkgs.fish;
      linger = true;
      hashedPasswordFile = config.sops.secrets."users/kuri/hashed-password".path;
    };
  };
}
