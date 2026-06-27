{
  config,
  pkgs,
  lib,
  ...
}: let
  # Scripts de filtrage fournis par le paquet aerc (le filtre html embarque w3m).
  aercFilters = "${pkgs.aerc}/libexec/aerc/filters";
  # Stylesets (thèmes) livrés avec le paquet aerc.
  aercStylesets = "${pkgs.aerc}/share/aerc/stylesets";
  # Stylesets custom déposés dans ./stylesets/*.styleset : tous auto-chargés.
  # Pour ajouter un thème, il suffit d'y déposer un fichier <nom>.styleset,
  # rebuild, puis `:reload -s <nom>` dans aerc.
  customStylesets =
    lib.mapAttrs' (
      file: _:
        lib.nameValuePair
        (lib.removeSuffix ".styleset" file)
        (builtins.readFile (./stylesets + "/${file}"))
    )
    (lib.filterAttrs
      (name: type: type == "regular" && lib.hasSuffix ".styleset" name)
      (builtins.readDir ./stylesets));
in {
  sops = {
    secrets = {
      "mail/password" = {};
      "mail/address" = {};
      "mail/tags/humanite" = {};
      "mail/tags/job" = {};
      "mail/tags/achats" = {};
      "mail/tags/mailinglist" = {};
      "mail/tags/spam" = {};
    };
  };

  services = {
    imapnotify.enable = true;
  };

  # On gère nous-mêmes le thème aerc (styleset catppuccin-mocha custom, vif,
  # avec fonds colorés) ; on désactive donc le styleset frappé fade que le
  # module catppuccin générait et imposait par défaut.
  catppuccin.aerc.enable = false;

  programs = {
    alot = {
      enable = true;
    };
    aerc = {
      enable = true;
      # Thèmes disponibles. catppuccin-mocha est notre styleset custom (défaut,
      # cf. ui.styleset-name) ; les autres viennent du paquet aerc. Switch à
      # chaud via `:reload -s <nom>` (complétion <Tab>), sans rebuild.
      stylesets =
        {
          catppuccin-mocha = ''
            *.default=true
            *.normal=true

            default.fg=#cdd6f4
            default.bg=#1e1e2e

            error.fg=#f38ba8
            error.bold=true
            warning.fg=#fab387
            success.fg=#a6e3a1

            # Titre (nom du compte, en haut à gauche) : pastille teal.
            title.fg=#1e1e2e
            title.bg=#94e2d5
            title.bold=true

            # Onglets : onglet sélectionné en pastille mauve.
            tab.fg=#9399b2
            tab.bg=#181825
            tab.selected.fg=#1e1e2e
            tab.selected.bg=#cba6f7
            tab.selected.bold=true

            border.fg=#45475a

            # Barre de statut (bas) : fond bleu plein, texte sombre.
            statusline_default.fg=#1e1e2e
            statusline_default.bg=#89b4fa
            statusline_default.bold=true
            statusline_error.fg=#1e1e2e
            statusline_error.bg=#f38ba8
            statusline_error.bold=true
            statusline_success.fg=#1e1e2e
            statusline_success.bg=#a6e3a1
            statusline_success.bold=true

            # Sidebar (dossiers) : même fond que la liste (sinon couture visible au
            # séparateur), sélection mauve pour repérer le dossier courant.
            dirlist_default.fg=#a6adc8
            dirlist_unread.fg=#cdd6f4
            dirlist_unread.bold=true
            dirlist_recent.fg=#a6e3a1
            dirlist_*.selected.fg=#1e1e2e
            dirlist_*.selected.bg=#cba6f7
            dirlist_*.selected.bold=true

            # Liste des messages : non-lus en bleu, lus en gris, sélection nette.
            msglist_default.fg=#cdd6f4
            msglist_unread.fg=#89b4fa
            msglist_unread.bold=true
            msglist_read.fg=#9399b2
            msglist_flagged.fg=#f38ba8
            msglist_flagged.bold=true
            msglist_deleted.fg=#6c7086
            msglist_deleted.dim=true
            msglist_marked.fg=#1e1e2e
            msglist_marked.bg=#f9e2af
            msglist_result.fg=#a6e3a1
            msglist_result.bold=true
            msglist_thread.fg=#7f849c
            msglist_*.selected.fg=#cdd6f4
            msglist_*.selected.bg=#45475a
            msglist_*.selected.bold=true
            msglist_gutter.bg=#1e1e2e
            msglist_pill.fg=#1e1e2e
            msglist_pill.bg=#cba6f7

            # Sélecteur / complétion (prompt de commande).
            selector_default.fg=#cdd6f4
            selector_focused.fg=#1e1e2e
            selector_focused.bg=#cba6f7
            selector_focused.bold=true
            completion_default.fg=#cdd6f4
            completion_gutter.bg=#181825
            completion_pill.fg=#1e1e2e
            completion_pill.bg=#cba6f7
            completion_description.fg=#a6adc8
            completion_description.dim=true

            # Sélecteur de parties MIME (bas du lecteur).
            part_switcher.bg=#181825
            part_mimetype.fg=#9399b2
            part_filename.fg=#a6adc8

            [viewer]
            header.fg=#cba6f7
            header.bold=true
            url.fg=#89dceb
            url.underline=true
            signature.fg=#7f849c
            signature.dim=true
            diff_meta.fg=#cba6f7
            diff_meta.bold=true
            diff_chunk.fg=#89b4fa
            diff_chunk_func.fg=#74c7ec
            diff_chunk_func.bold=true
            diff_add.fg=#a6e3a1
            diff_del.fg=#f38ba8
            quote_1.fg=#a6e3a1
            quote_2.fg=#94e2d5
            quote_3.fg=#fab387
            quote_4.fg=#f5c2e7
            quote_x.fg=#9399b2
          '';
          nord = builtins.readFile "${aercStylesets}/nord";
          dracula = builtins.readFile "${aercStylesets}/dracula";
          solarized-dark = builtins.readFile "${aercStylesets}/solarized-dark";
          solarized = builtins.readFile "${aercStylesets}/solarized";
        }
        // customStylesets;
      extraConfig = {
        # accounts.conf vit dans le Nix store (lisible par tous) ; il ne
        # contient aucun mot de passe en clair, juste un passwordCommand.
        general.unsafe-accounts-conf = true;
        ui = {
          threading-enabled = true;
          sidebar-width = 25;
          styleset-name = "nocturne";
          # Préférer la partie text/html (rendue via le filtre html/w3m) à la
          # partie text/plain, souvent bâclée (HTML brut) dans les newsletters.
          alternatives = "text/html,text/plain";
          # Glyphes de la colonne flags, au lieu des lettres N/O/r/f/!/*/d/X.
          # new + old = non lu (un mail lu n'affiche rien) → même pastille.
          icon-new = "●";
          icon-old = "●";
          icon-replied = "↪";
          icon-forwarded = "⤳";
          icon-flagged = "★";
          icon-marked = "✓";
          icon-draft = "✎";
          icon-deleted = "✗";
          icon-attachment = "@";
        };
        # Sans ces filtres, aerc n'affiche pas le corps des mails
        # ("No filter configured for this mimetype").
        filters = {
          "text/plain" = "${aercFilters}/colorize";
          "text/calendar" = "${aercFilters}/calendar";
          "message/delivery-status" = "${aercFilters}/colorize";
          "message/rfc822" = "${aercFilters}/colorize";
          "text/html" = "${aercFilters}/html";
          "text/*" = "${aercFilters}/wrap -w 100 | ${aercFilters}/colorize";
        };
      };
    };
    msmtp.enable = true;
    offlineimap.enable = true;
    notmuch = {
      enable = true;
      hooks = {
        postNew = ''
          xargs -P 5 -I {} notmuch tag +ml -- tag:new {} < ${config.sops.secrets."mail/tags/mailinglist".path}
          xargs -P 5 -I {} notmuch tag +ml -- tag:unread {} < ${config.sops.secrets."mail/tags/mailinglist".path}
          xargs -P 5 -I {} notmuch tag +spam +killed -new -- tag:new {} < ${config.sops.secrets."mail/tags/spam".path}
          xargs -P 5 -I {} notmuch tag +achats -new -- tag:new {} < ${config.sops.secrets."mail/tags/achats".path}
          xargs -P 5 -I {} notmuch tag +job -- tag:new {} < ${config.sops.secrets."mail/tags/job".path}
          xargs -P 5 -I {} notmuch tag +humanite -- tag:new {} < ${config.sops.secrets."mail/tags/humanite".path}
          xargs -P 5 -I {} notmuch tag +creditagricole -- tag:new {} < ${config.sops.secrets."mail/tags/creditagricole".path}
          notmuch tag +inbox +unread -new -- tag:new
          notmuch tag -new -unread +sent -- from:$(cat ${config.sops.secrets."mail/address".path})
          notmuch tag +EGIT -inbox -- 'to:git@lists.enlightenment.org'
          notmuch tag +github -- from:notifications@github.com and tag:inbox
          notmuch tag '+oss-security' 'subject:\[oss-security\]' and tag:inbox
          notmuch tag +free -- 'from:freemobile@free-mobile.fr' and tag:inbox
        '';
      };
    };
  };

  # Vues notmuch pour aerc, alimentées par les tags posés dans les hooks
  # notmuch ci-dessus (programs.notmuch.hooks.postNew).
  xdg.configFile."aerc/friloux.qmap".text = ''
    Inbox=tag:inbox
    Non lus=tag:unread
    Envoyés=tag:sent
    Job=tag:job
    Achats=tag:achats
    Humanité=tag:humanite
    Mailing lists=tag:ml
    Spam=tag:spam
    Tous=*
  '';

  accounts.email = {
    maildirBasePath = "mail";
    accounts.friloux = {
      address = "guillaume@friloux.me";
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
      aerc = {
        enable = true;
        # Backend notmuch : pas de dossiers, on mappe des vues sur tes tags.
        extraAccounts = {
          query-map = "${config.xdg.configHome}/aerc/friloux.qmap";
          exclude-tags = "killed,spam";
        };
      };
      imapnotify = {
        enable = true;
        onNotify = "${pkgs.offlineimap}/bin/offlineimap";
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
          localfolders = "${config.home.homeDirectory}/mail/friloux";
        };
        extraConfig.remote.folderfilter = "lambda folder: folder in ['INBOX', 'Sent']";
      };
    };
  };
}
