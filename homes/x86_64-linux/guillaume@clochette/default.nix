{
    lib,
    pkgs,
    inputs,
    namespace,
    home,
    target,
    format,
    virtual,
    host,
    config,
    nix-cli,
    nix-gui,
    ...
}:
{
  imports = [
    inputs.nix-cli.homeModules.default
  ];

  nix-cli.hm.enable = true;
  
  home = {
    stateVersion = "24.11";

    username = "guillaume";
    homeDirectory = "/home/guillaume";

    keyboard = {
      layout = "fr";
    };
    sessionVariables = {
      EDITOR = "micro";
      MICRO_TRUECOLOR=1;
      VISUAL="micro";
    };
    language = {
      base = "fr_FR.UTF-8";
    };
    enableNixpkgsReleaseCheck = false;
    packages = with pkgs; [
      fastfetch
      ouch
      aria2
      htop
      unzip
      cmatrix
      nvd
      openssl
    ];
  };

  programs = {
    home-manager.enable = true;
    fish = {
      enable = true;
    };
  };
}
