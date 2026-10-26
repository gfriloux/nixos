{inputs, ...}: {
  imports = [
    inputs.sops-nix.nixosModules.sops
    inputs.disko.nixosModules.disko
    inputs.stc.nixosModules.relics-hardening-ssh
    inputs.stc.nixosModules.relics-nix-housekeeping
    ./hardware-configuration.nix
    ./disko.nix
    ./network.nix
    ./users.nix
  ];

  stc.relics = {
    nixHousekeeping.enable = true;
    hardening.ssh.enable = true;
  };

  sops = {
    defaultSopsFile = ../../../secrets/skitarii.yaml;
    # La clé hôte est générée avant l'installation et déposée par
    # nixos-anywhere (--extra-files), pour que sops marche dès le premier boot.
    age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
    secrets."users/guillaume/hashed-password".neededForUsers = true;
  };

  boot.loader.grub.enable = true;

  time.timeZone = "Europe/Paris";

  i18n.defaultLocale = "fr_FR.UTF-8";

  nix.settings.trusted-users = ["root" "guillaume"];

  services.openssh.settings.AllowUsers = ["guillaume"];

  programs.fish.enable = true;

  system.stateVersion = "26.05";
}
