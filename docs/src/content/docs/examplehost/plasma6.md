---
title: The Sacred Desktop — Plasma 6 & Wayland
description: SDDM, Plasma 6 configuration, Pipewire audio, XDG portal setup.
---

The sacred desktop environment runs Plasma 6 in native Wayland mode, blessed with Pipewire for audio.

## Configuration

```nix
services.displayManager.sddm = {
  enable = true;
  wayland.enable = true;
};
services.desktopManager.plasma6.enable = true;
```

Native Wayland session. `services.xserver.enable = false` (Xwayland available via `xwayland-satellite` for X11 applications if needed).

Keyboard layout: `fr` (console and Xkb).

## Theme

Dracula theme configured via Home Manager (package `dracula-theme`).
GTK4: `gtk-application-prefer-dark-theme=1`.

## Pipewire — The Sound Spirit

PulseAudio is absent. Pipewire orchestrates audio with ALSA and PulseAudio compatibility:

```bash
# Verify Pipewire runs
systemctl --user status pipewire wireplumber

# Command-line mixer
pulsemixer
# or
pavucontrol  # graphical UI
```

## XDG Applications Portal

XDG portal is activated with `xdg-desktop-portal-gtk` as secondary backend.
`services.gvfs.enable = true` for file manager integration.
