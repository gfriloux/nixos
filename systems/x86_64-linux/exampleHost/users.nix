{pkgs, ...}: {
  users.users.kuri = {
    openssh.authorizedKeys.keys = ["sshKey_placeholder"];
    isNormalUser = true;
    extraGroups = ["users" "networkmanager" "video" "audio" "docker" "wheel" "disk"];
    shell = pkgs.fish;
    linger = true;
  };
}
