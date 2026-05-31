{
  lib,
  pkgs,
  inputs,
  config,
  ...
}: {
  imports = [
    inputs.stc.homeModules.cogitator-enginseer
    inputs.stc.homeModules.cogitator-desktop
    inputs.stc.homeModules.relics-yubikey-user
    inputs.sops-nix.homeManagerModules.sops
    inputs.pgpilot.homeModules.pgpilot
    inputs.stc.homeModules.relics-plasma-manager
    ./ssh.nix
    ./mail.nix
  ];

  stc = {
    cogitator.enginseer.enable = true;
    cogitator.desktop.enable = true;
    yubikey.enable = true;
    plasmaManager.enable = true;
  };
  pgpilot.pgpilot.enable = true;

  programs.ghostty = {
    settings.copy-on-select = "clipboard";
    systemd.enable = true;
  };

  sops = {
    age.keyFile = "/etc/sops/age/keys.txt";
    defaultSopsFile = ../../../secrets/kuri_exampleHost.yaml;
    defaultSymlinkPath = "/run/user/1000/secrets";
    defaultSecretsMountPoint = "/run/user/1000/secrets.d";

    secrets = {
      "rbw/server" = {
        path = "${config.sops.defaultSymlinkPath}/rbw_server";
      };
      "workspace" = {
        path = "${config.sops.defaultSymlinkPath}/workspace";
      };
    };
  };

  home = {
    stateVersion = "24.11";

    username = "kuri";
    homeDirectory = "/home/kuri";

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
      glibcLocales
      imagemagick
      folder-color-switcher
      catppuccin-kde
      dconf
      dconf-editor
      pinentry-gtk2
      ffmpeg
      dosbox-x
      transmission_4-qt6
      heroic
      scummvm
      ryubing
      winetricks
      wineWow64Packages.staging
      appimage-run
      steam-run
      flatpak-builder
      appstream
      appstream-glib
      #rustdesk
      cargo-binstall
      kooha
      gparted
      ouch
      aria2
      htop
      unzip
      cmatrix
      flameshot
      rustup
      gcc
      protonup-ng
      scanmem
      bonnie
      ueberzug
      docker-compose
      pavucontrol
      pulsemixer
      w3m
      (python3.withPackages (python-pkgs:
        with python-pkgs; [
          tqdm
          inquirerpy
          requests
        ]))
      #fido2-manage
      vesktop
      pcsx2
      (writeShellScriptBin "rbw-wrapper" ''
        export RBW_EMAIL="$(cat ${config.sops.secrets."mail/address".path})"
        export RBW_SERVER="$(cat ${config.sops.secrets."rbw/server".path})"
        rbw config set email "$RBW_EMAIL"
        rbw config set base_url "$RBW_SERVER"
        exec ${pkgs.rbw}/bin/rbw "$@"
      '')
    ];

    file.".mailcap".source = ./mailcap;
    file.".ssh/sockets/.keep".text = "";
  };

  fonts = {
    fontconfig.enable = true;
  };

  news = {
    display = "silent";
    json = lib.mkForce {};
    entries = lib.mkForce [];
  };

  gtk = {
    enable = true;

    font = {
      name = "Iosevka";
      package = pkgs.iosevka;
      size = 7;
    };

    gtk4 = {
      extraConfig = {
        Settings = ''
          gtk-application-prefer-dark-theme=1
        '';
      };
      theme = null; # adopts new HM default (stateVersion < 26.05 uses config.gtk.theme)
    };
  };

  systemd.user.targets.tray = {
    Unit = {
      Description = "Home Manager System Tray";
      Requires = ["graphical-session-pre.target"];
    };
  };

  services = {
    network-manager-applet.enable = true;
    gpg-agent = {
      enable = true;
      pinentry.package = lib.mkForce pkgs.pinentry-qt;
      enableSshSupport = false;
      enableFishIntegration = true;
    };
  };

  programs = {
    micro = {
      settings = {
        tabsize = 2;
        tabstospaces = true;
        autoindent = true;
        ruler = true;
        savecursor = true;
        mouse = true;
        "lsp.server" = "nix:nixd";
      };
    };
    claude-code = {
      enable = true;
    };
    nix-search-tv = {
      enable = true;
      enableTelevisionIntegration = true;
    };
    home-manager.enable = true;
    plasma = {
      workspace = {
        lookAndFeel = "Catppuccin-Mocha-Global";
        colorScheme = "CatppuccinMocha";
        iconTheme = "Papirus-Dark";
        cursor = {
          theme = "Catppuccin-Mocha-Dark-Cursors";
          size = 24;
        };
      };
    };
    gpg.enable = true;
    git = {
      signing = {
        key = "52381C92A5071464F3160D257D4216D8BDDA9A09";
        signByDefault = true;
        format = null; # adopts new HM default (stateVersion < 25.05 uses "openpgp")
      };
      settings.user = {
        email = "guillaume@friloux.me";
        name = "Guillaume Friloux";
      };
    };
    fish = {
      enable = true;
      plugins = [
        {
          name = "nix-env";
          src = pkgs.fetchFromGitHub {
            owner = "lilyball";
            repo = "nix-env.fish";
            rev = "7b65bd228429e852c8fdfa07601159130a818cfa";
            sha256 = "RG/0rfhgq6aEKNZ0XwIqOaZ6K5S4+/Y5EEMnIdtfPhk=";
          };
        }
      ];
      functions = {
        envsource = ''
          for line in (cat $argv | grep -v '^#')
            set item (string split -m 1 '=' $line)
            set -gx $item[1] $item[2]
          end
        '';
      };
      shellAliases = {
        alot = "alot -n ~/.config/notmuch/default/config";
        rbw = "rbw-wrapper";
      };
      shellInitLast = ''
        envsource /run/user/1000/secrets/workspace
        set -gx SSH_AUTH_SOCK "/run/user/1000/ssh-agent"
      '';
    };
  };
}
