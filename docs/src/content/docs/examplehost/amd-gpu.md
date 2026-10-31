---
title: "AMD GPU"
description: amdgpu through STC's amdGpu relic, checks.
---

`stc.relics.amdGpu.initrd = true;` in `default.nix`. What the relic sets (evaluated):

```nix
boot.initrd.kernelModules = [ "amdgpu" ];   # display from early boot
hardware.graphics = {
  enable = true;
  enable32Bit = true;
  extraPackages = with pkgs; [ libvdpau libva-vdpau-driver ];
};
services.xserver.enable = false;   # Plasma on Wayland (KMS), SDDM in Wayland mode
```

```bash
glxinfo | grep "OpenGL renderer"   # active renderer
vainfo                             # VA-API video acceleration
clinfo | head -20                  # OpenCL, if available
```
