---
title: GPU AMD
description: Configuration du GPU AMD — amdgpu, ROCM, accélération vidéo.
---

GPU AMD configuré avec support complet pour l'accélération vidéo et l'affichage Wayland.

## Configuration

```nix
hardware.graphics = {
  enable = true;
  enable32Bit = true;
  extraPackages = with pkgs; [
    libvdpau
    libva-vdpau-driver
  ];
};
```

Le module kernel `amdgpu` est chargé dès l'initrd pour l'affichage au boot.

## Vérification

```bash
# Renderer actif
glxinfo | grep "OpenGL renderer"
# Exemple : AMD Radeon RX 6700 XT (navi22, LLVM ...)

# Accélération vidéo VA-API
vainfo

# Informations GPU
clinfo | head -20  # si opencl disponible
```

## Plasma 6 & Wayland

L'affichage Wayland utilise nativement `amdgpu` via KMS.
Pas de configuration Xorg nécessaire (`services.xserver.enable = false`).

KWin (Plasma) tourne en mode Wayland natif via SDDM Wayland.
