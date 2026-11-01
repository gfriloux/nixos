---
title: "Plasma 6"
description: SDDM, Plasma 6 sous Wayland, Pipewire, portails XDG, thème.
---

`stc.relics.plasma6` (clavier `fr`, thème sddm `catppuccin-mocha-mauve`) et `stc.cogitator.workstation` dans `default.nix`. Config effective (évaluée) :

```nix
services.displayManager.sddm = {
  enable = true;
  wayland.enable = true;
  theme = "catppuccin-mocha-mauve";      # paquet catppuccin-sddm
};
services.desktopManager.plasma6.enable = true;
services.xserver.enable = false;         # Wayland uniquement ; xwayland-satellite installé pour les applis X11
services.xserver.xkb.layout = "fr";
console.keyMap = "fr";

services.pulseaudio.enable = false;
services.pipewire = { enable = true; alsa.enable = true; pulse.enable = true; };

xdg.portal.enable = true;                # portails : kde, gtk, kwallet
services.gvfs.enable = true;             # intégration du gestionnaire de fichiers
```

Thème (Home Manager) : `catppuccin-kde`, police GTK Iosevka 7, GTK4 `gtk-application-prefer-dark-theme=1`.

```bash
systemctl --user status pipewire wireplumber
pulsemixer       # ou pavucontrol
```
