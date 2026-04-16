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
      linger = true;
      home = "/home/guillaume";
      description = "Moi";
      extraGroups = ["wheel" "docker"];
      useDefaultShell = true;
      hashedPasswordFile = config.sops.secrets."users/guillaume/hashed-password".path;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIETPEOCEETy3EHFswjsoEsMmu4i7TUPCXwPrhVsjH8rE guillaume+perso@friloux.me"
        "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIFE9OazubAILNGPXMxVPBK4vgFVNth2G67JWN3wnB4+tAAAADXNzaDpjbG9jaGV0dGU= clochette@friloux.me"
      ];
      shell = pkgs.fish;
    };

    users.weechat = {
      createHome = true;
      isNormalUser = true;
      linger = true;
      home = "/home/weechat";
      description = "Moi";
      useDefaultShell = true;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIETPEOCEETy3EHFswjsoEsMmu4i7TUPCXwPrhVsjH8rE guillaume+perso@friloux.me"
        "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIP69OQvGEPoEZU8pSCRKDprle3C9UGqbt/52t6NG5GWYAAAADnNzaDphcHB3ZWVjaGF0 weechat@irc.friloux.me"
      ];
      shell = pkgs.fish;
    };
  };
}
