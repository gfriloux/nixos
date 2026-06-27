# DankMaterialShell — barre de bureau (Quickshell)
#
# Module Home Manager autonome qui enveloppe le module de la flake DMS.
# Le namespace reste local (kuri.dank-shell) pour pouvoir transposer ce
# module vers un dépôt partagé plus tard avec un simple `git mv` + un
# renommage de namespace.
{
  config,
  lib,
  inputs,
  ...
}: let
  cfg = config.kuri.dank-shell;
in {
  imports = [
    inputs.dms.homeModules.dank-material-shell
    inputs.astropath.homeModules.default
  ];

  options.kuri.dank-shell.enable = lib.mkEnableOption "DankMaterialShell desktop bar";

  config = lib.mkIf cfg.enable {
    # Plugin mail notmuch — déposé dans ~/.config/DankMaterialShell/plugins/,
    # à activer ensuite dans DMS (Settings → Plugins → Astropath). L'état
    # d'activation va dans plugin_settings.json (séparé du settings.json figé).
    programs.astropath.enable = true;

    programs.dank-material-shell = {
      enable = true;
      systemd.enable = true;

      # Moniteur système (CPU / température) fourni en natif — pas de plugin.
      enableSystemMonitoring = true;

      # On garde Catppuccin Mocha fixe : on coupe le theming dynamique
      # (Matugen, dérivé du wallpaper).
      enableDynamicTheming = false;

      # Snapshot figé de la configuration GUI (cf. ./settings.json).
      # Dès lors que `settings` est non vide, le module écrit
      # ~/.config/DankMaterialShell/settings.json en symlink read-only vers
      # le store : les réglages GUI ne persistent plus, tout changement passe
      # désormais par Nix + rebuild.
      #
      # `customThemeFile` est réécrit pour pointer vers la palette Catppuccin
      # (Mocha/Mauve) embarquée dans le module → reproductible, sans dépendre
      # du thème téléchargé depuis le registry DMS.
      settings =
        (builtins.fromJSON (builtins.readFile ./settings.json))
        // {
          customThemeFile = "${./themes/catppuccin.json}";
        };
    };
  };
}
