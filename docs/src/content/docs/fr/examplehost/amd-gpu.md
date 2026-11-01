---
title: "GPU AMD"
description: amdgpu via la relic amdGpu de STC, vérifications.
---

`stc.relics.amdGpu.initrd = true;` dans `default.nix`. Ce que la relic pose (évalué) :

```nix
boot.initrd.kernelModules = [ "amdgpu" ];   # affichage dès le début du boot
hardware.graphics = {
  enable = true;
  enable32Bit = true;
  extraPackages = with pkgs; [ libvdpau libva-vdpau-driver ];
};
services.xserver.enable = false;   # Plasma sous Wayland (KMS), SDDM en mode Wayland
```

```bash
glxinfo | grep "OpenGL renderer"   # moteur de rendu actif
vainfo                             # accélération vidéo VA-API
clinfo | head -20                  # OpenCL, si disponible
```
