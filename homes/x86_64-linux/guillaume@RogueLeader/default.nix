{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    inputs.stc.homeModules.cogitator-enginseer
  ];

  stc = {
    cogitator.enginseer.enable = true;
  };

  home = {
    stateVersion = "25.11";

    username = "guillaume";
    homeDirectory = "/home/guillaume";

    keyboard = {
      layout = "fr";
    };
    sessionVariables = {
      EDITOR = "micro";
      MICRO_TRUECOLOR = 1;
      VISUAL = "micro";
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
