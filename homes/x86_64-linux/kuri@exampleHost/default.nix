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
        # sopsFile = ./secrets.yml.enc; # optionally define per-secret files
        path = "${config.sops.defaultSymlinkPath}/mail_password";
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
      trunk-ng
      dart-sass
      fastfetch
      wlr-randr
      git-workspace
      kooha
      ghostty
      gimp
      heroic
      scummvm
      ryubing
      transmission_4-qt6
      discord
      betterdiscordctl
      libreoffice
      gparted
      ouch
      aria2
      htop
      unzip
      cmatrix
      flameshot
      pegasus-frontend
      nvd
      libfido2
      #fido2-manage
      yubikey-manager
      yubikey-touch-detector
      itgmania
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
      };
      shellInitLast = ''
        envsource ~/.config/env_secrets
        set -gx SSH_AUTH_SOCK "/run/user/1000/ssh-agent"
      '';
    };
    notmuch = {
      enable = true;
      hooks = {
        postNew = ''
          notmuch tag +inbox +unread -new -- tag:new
          notmuch tag -new -unread +sent -- from:guillaume@friloux.me
          notmuch tag +achats -new -unread -killed -- 'from:service@paypal.fr' or 'subject:Votre commande sur LDLC' or 'subject:Votre commande Amazon.fr.*'
          notmuch tag +frsag -new -unread -- 'to:frsag@frsag.org'
          notmuch tag +dmarc -new -unread -inbox -- 'subject:.*Report Domain: friloux.me.*'
          notmuch tag +smashingmagazine +ml -new -unread -inbox -- 'from:newsletter@smashingmagazine.com'
          notmuch tag +EGIT +ml -new -unread -inbox -- 'to:git@lists.enlightenment.org'
          notmuch tag +softwarelead +ml -new -unread -inbox -- 'to:guillaume+softwareleadweekly@friloux.me'
          notmuch tag +killed -inbox -new -unread -- 'from:cws-noreply@google.com'            \
                                                  or 'from:bugzilla-noreply@freebsd.org'      \
                                                  or 'from:fulldisclosure@seclists.org'       \
                                                  or 'from:contact@mailer.humblebundle.com'   \
                                                  or 'from:info@news.ovhcloud.com'            \
                                                  or 'from:hello@molotov.tv'                  \
                                                  or 'from:contact@mail-agilauto-ca.fr'       \
                                                  or 'from:no-reply@primevideo.com'           \
                                                  or 'to:guillaume+ollygan@friloux.me'        \
                                                  or 'to:oss-security@lists.openwall.com'     \
                                                  or 'from:developer@insideapple.apple.com'   \
                                                  or 'from:opel@contactopel.com'              \
                                                  or 'from:administration@conservatoire40.fr' \
                                                  or 'from:ptm@conservatoire40.fr'            \
                                                  or 'from:noreply-maps-timeline@google.com'  \
                                                  or 'from:newsletter@elements.scaleway.com'  \
                                                  or 'from:notifications@educartable.com'     \
                                                  or 'from:tooketspg@ca-pyrenees-gascogne.fr' \
                                                  or 'from:paypal@mail.paypal.frpaypal@mail.paypal.fr'
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
      passwordCommand = "/run/current-system/sw/bin/cat /run/user/1000/secrets/mail_password";
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
