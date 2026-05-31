---
title: The Machine-Vision — AMD GPU Configuration
description: AMDGPU driver setup, verification, and Wayland integration with Plasma 6.
---

The machine-spirit's vision is blessed with an AMD GPU. The `amdgpu` driver is consecrated at boot.

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

The `amdgpu` kernel module is loaded in the initrd for display at boot.

## Verification

```bash
# Active renderer
glxinfo | grep "OpenGL renderer"
# Example: AMD Radeon RX 6700 XT (navi22, LLVM ...)

# Video acceleration (VA-API)
vainfo

# GPU info
clinfo | head -20  # if OpenCL available
```

## Plasma 6 & Wayland

Wayland display natively uses `amdgpu` via KMS.
No Xorg configuration is required (`services.xserver.enable = false`).

KWin (Plasma) runs in native Wayland mode via SDDM Wayland.
