# configuration in this file only applies to exampleHost host
#
# only zfs-root.* options can be defined in this file.
#
# all others goes to `configuration.nix` under the same directory as
# this file. 

_: {
  #inherit pkgs system;
  zfs-root = {
    boot = {
      devNodes = "/dev/disk/by-id/";
      bootDevices = [  "nvme-Samsung_SSD_980_PRO_1TB_S5GXNL0W810368E" "nvme-Samsung_SSD_980_PRO_1TB_S5GXNL0W810454N" ];
      immutable = false;
      availableKernelModules = [  "xhci_pci" "ehci_pci" "nvme" "usb_storage" "usbhid" "sd_mod" "amdgpu" ];
      removableEfi = true;
      kernelParams = [ ];
      sshUnlock = {
        enable = false;
        authorizedKeys = [ ];
      };
    };
    networking = {
      hostName = "exampleHost";
      timeZone = "Europe/Paris";
      hostId = "21ed29b1";
    };
  };
}
