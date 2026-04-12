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
    inputs.nix-gui.homeModules.default
    inputs.sops-nix.homeManagerModules.sops
  ];

  nix-cli.hm.enable = true;
  nix-gui.hm.enable = true;

  sops = {
    #age.keyFile = "/home/<your username>/.config/sops/age/keys.txt"; # must have no password!
    gnupg.home = "/home/kuri/.gnupg";
    defaultSopsFile = ../../../secrets/kuri_exampleHost.yaml;
    defaultSymlinkPath = "/run/user/1000/secrets";
    defaultSecretsMountPoint = "/run/user/1000/secrets.d";
  
    secrets."mail/password" = {
      path = "${config.sops.defaultSymlinkPath}/mail_password";
    };
    secrets."mail/address" = {
      path = "${config.sops.defaultSymlinkPath}/mail_address";
    };
    secrets."mail/tags/humanite" = {
      path = "${config.sops.defaultSymlinkPath}/mail_tags_humanite";
    };
    secrets."mail/tags/job" = {
      path = "${config.sops.defaultSymlinkPath}/mail_tags_job";
    };
    secrets."mail/tags/achats" = {
      path = "${config.sops.defaultSymlinkPath}/mail_tags_achats";
    };
    secrets."mail/tags/mailinglist" = {
      path = "${config.sops.defaultSymlinkPath}/mail_tags_mailinglist";
    };
    secrets."mail/tags/spam" = {
      path = "${config.sops.defaultSymlinkPath}/mail_tags_spam";
    };
    secrets."rbw/server" = {
      path = "${config.sops.defaultSymlinkPath}/rbw_server";
    };
    secrets."workspace" = {
      path = "${config.sops.defaultSymlinkPath}/workspace";
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
      MICRO_TRUECOLOR=1;
      VISUAL="micro";
    };
    language = {
      base = "fr_FR.UTF-8";
    };
    enableNixpkgsReleaseCheck = false;

    packages = with pkgs; [
      glibcLocales
      imagemagick
      folder-color-switcher
      dracula-theme
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
      steam
      appimage-run
      steam-run
      flatpak-builder
      appstream
      appstream-glib
      #rustdesk
      cargo-binstall
      fastfetch
      git-workspace
      kooha
      ghostty
      gimp
      heroic
      scummvm
      ryubing
      transmission_4-qt6
      gparted
      ouch
      aria2
      htop
      unzip
      cmatrix
      flameshot
      nvd
      libfido2
      #fido2-manage
      yubikey-manager
      yubikey-touch-detector
      vesktop
      (writeShellScriptBin "rbw-wrapper" ''
        export RBW_EMAIL="$(cat ${config.sops.secrets."mail/address".path})"
        export RBW_SERVER="$(cat ${config.sops.secrets."rbw/server".path})"
        rbw config set email "$RBW_EMAIL"
        rbw config set base_url "$RBW_SERVER"
        exec ${pkgs.rbw}/bin/rbw "$@"
      '')
    ];

    file.".mailcap".source = ./mailcap;
  };

  fonts = {
  	fontconfig.enable = true;
  };

  targets.genericLinux.enable=true;

  news = {
    display = "silent";
    json = lib.mkForce {};
    entries = lib.mkForce [];
  };

  gtk = {
    enable = true;

    font = {
      name    = "Iosevka 8";
      package = pkgs.iosevka;
      size    = 7;
    };

    gtk4.extraConfig = {
      Settings = ''
        gtk-application-prefer-dark-theme=1
      '';
    };
  };

  systemd.user.targets.tray = {
    Unit = {
      Description = "Home Manager System Tray";
      Requires = [ "graphical-session-pre.target" ];
    };
  };

  services = {
  	network-manager-applet.enable = true;
  	gpg-agent = {
  	  enable = true;
  	  pinentry.package = lib.mkForce pkgs.pinentry-qt;
  	  enableSshSupport = true;
  	  enableFishIntegration = true;
  	};
  	ssh-agent = {
  	  enable = true;
  	  enableFishIntegration = true;
  	};
  	imapnotify.enable = true;
  };

  programs = {
    alot = {
      enable = true;
    };
    home-manager.enable = true;
    msmtp.enable = true;
    offlineimap.enable = true;
    gpg.enable = true;
    direnv.enable = true;
    git = {
      signing = {
        key = "4DF35290882C2927ACD88A4F6FCA9BE19FC69E48";
        signByDefault = true;
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
    notmuch = {
      enable = true;
      hooks = {
        postNew = ''
          xargs -P 5 -I {} notmuch tag +ml -- tag:new {} < ${config.sops.secrets."mail/tags/mailinglist".path}
          xargs -P 5 -I {} notmuch tag +spam +killed -new -- tag:new {} < ${config.sops.secrets."mail/tags/spam".path}
          xargs -P 5 -I {} notmuch tag +achats -new -- tag:new {} < ${config.sops.secrets."mail/tags/achats".path}
          xargs -P 5 -I {} notmuch tag +job -new -- tag:new {} < ${config.sops.secrets."mail/tags/job".path}
          xargs -P 5 -I {} notmuch tag +humanite -new -- tag:new {} < ${config.sops.secrets."mail/tags/humanite".path}
          notmuch tag +inbox +unread -new -- tag:new
          notmuch tag -new -unread +sent -- from:$(cat ${config.sops.secrets."mail/address".path})
          notmuch tag +EGIT -new -unread -inbox -- 'to:git@lists.enlightenment.org'
          notmuch tag
        '';
      };
    };  
  };

  accounts.email = {
    maildirBasePath = "mail";
    accounts.friloux = {
      address  = "guillaume@friloux.me";
      userName = "guillaume@friloux.me";
      realName = "Guillaume FRILOUX";
      imap = {
        host = "mx.friloux.me";
        port = 993;
        tls.enable = true;
      };
      smtp.host = "mx.friloux.me";
      smtp.tls.enable = true;
      primary = true;
      passwordCommand = "/run/current-system/sw/bin/cat ${config.sops.secrets."mail/password".path}";
      notmuch.enable = true;
      imapnotify = {
      	enable = true;
      	onNotify = "/home/kuri/.nix-profile/bin/offlineimap";
      	boxes = [
      	  "Inbox"
      	];
      };
      msmtp = {
        enable = true;
        extraConfig = {
          from = "guillaume@friloux.me";
          auth = "plain";
        };
      };
      offlineimap = {
        enable = true;
        postSyncHookCommand = "notmuch new";
        extraConfig.local = {
          localfolders = "/home/kuri/mail/friloux";
        };        
        extraConfig.remote.folderfilter = "lambda folder: folder in ['INBOX', 'Sent']";
      };
    };
  };
}
