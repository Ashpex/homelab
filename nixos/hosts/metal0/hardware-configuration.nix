# Hardware-specific settings for mini PC class nodes.
#
# Disk layout is managed by disko, so this file intentionally does not define
# `fileSystems` entries for `/` or `/boot`.
{ lib, ... }:

{
  boot.initrd.availableKernelModules = [
    "ahci"
    "nvme"
    "sd_mod"
    "usb_storage"
    "usbhid"
    "xhci_pci"
  ];

  boot.kernelModules = [
    "kvm-intel"
  ];

  hardware.cpu.intel.updateMicrocode = lib.mkDefault true;
  hardware.enableRedistributableFirmware = true;
  nixpkgs.hostPlatform = "x86_64-linux";
}
