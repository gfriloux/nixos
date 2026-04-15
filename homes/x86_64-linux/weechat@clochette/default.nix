{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    inputs.nix-cli.homeModules.default
  ];

  nix-cli.hm.enable = true;

  home = {
    stateVersion = "25.05";

    username = "weechat";
    homeDirectory = "/home/weechat";

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
      weechat
      zellij
    ];
  };

  programs = {
    home-manager.enable = true;
    fish = {
      enable = true;
    };
  };
}
