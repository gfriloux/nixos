---
title: "Plasma 6"
description: SDDM, Plasma 6 on Wayland, Pipewire, XDG portals, theme.
---

`stc.relics.plasma6` (layout `fr`, sddm theme `catppuccin-mocha-mauve`) and `stc.cogitator.workstation` in `default.nix`. Effective config (evaluated):

```nix
services.displayManager.sddm = {
  enable = true;
  wayland.enable = true;
  theme = "catppuccin-mocha-mauve";      # package catppuccin-sddm
};
services.desktopManager.plasma6.enable = true;
services.xserver.enable = false;         # Wayland only; xwayland-satellite installed for X11 apps
services.xserver.xkb.layout = "fr";
console.keyMap = "fr";

services.pulseaudio.enable = false;
services.pipewire = { enable = true; alsa.enable = true; pulse.enable = true; };

xdg.portal.enable = true;                # portals: kde, gtk, kwallet
services.gvfs.enable = true;             # file manager integration
```

Theme (Home Manager): `catppuccin-kde`, GTK font Iosevka 7, GTK4 `gtk-application-prefer-dark-theme=1`.

```bash
systemctl --user status pipewire wireplumber
pulsemixer       # or pavucontrol
```
