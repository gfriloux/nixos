{config, ...}: {
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

  programs = {
    alot = {
      enable = true;
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
          xargs -P 5 -I {} notmuch tag +job -new -- tag:new {} < ${config.sops.secrets."mail/tags/job".path}
          xargs -P 5 -I {} notmuch tag +humanite -new -- tag:new {} < ${config.sops.secrets."mail/tags/humanite".path}
          notmuch tag +inbox +unread -new -- tag:new
          notmuch tag -new -unread +sent -- from:$(cat ${config.sops.secrets."mail/address".path})
          notmuch tag +EGIT -new -unread -inbox -- 'to:git@lists.enlightenment.org'
        '';
      };
    };
  };

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
