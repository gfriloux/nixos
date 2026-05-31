---
title: Plasma 6
description: Configuration de KDE Plasma 6 en Wayland — SDDM, thème, audio pipewire.
---

KDE Plasma 6 configuré en session Wayland native pour un environnement de bureau moderne et fluide.

## Configuration

```nix
services.displayManager.sddm = {
  enable = true;
  wayland.enable = true;
};
services.desktopManager.plasma6.enable = true;
```

Session Wayland native. `services.xserver.enable = false` (Xwayland disponible
via `xwayland-satellite` pour les applications X11 si nécessaire).

Disposition clavier : `fr` (console et Xkb).

## Thème

Thème Dracula configuré via Home Manager (paquet `dracula-theme`).
GTK4 : `gtk-application-prefer-dark-theme=1`.

## Pipewire / Audio

PulseAudio est désactivé. Pipewire gère l'audio avec compatibilité ALSA et PulseAudio :

```bash
# Vérifier que Pipewire tourne
systemctl --user status pipewire wireplumber

# Mixer (CLI)
pulsemixer
# ou
pavucontrol  # UI graphique
```

## Applications XDG

Portal XDG activé avec `xdg-desktop-portal-gtk` en backend secondaire.
`services.gvfs.enable = true` pour l'intégration gestionnaire de fichiers.
