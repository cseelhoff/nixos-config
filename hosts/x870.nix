{ config, pkgs, lib, ... }:

{
  imports = [
    ../hardware/x870-hardware-configuration.nix
    ../modules/gui.nix
    ../modules/nvidia.nix
    ../modules/gaming.nix
  ];

  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 10;
      editor = false;
    };
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };
    grub.enable = false;
  };

  # Host-specific kernel params. NVIDIA-related params live in modules/nvidia.nix.
  boot.kernelParams = [
    "usbcore.autosuspend=-1"  # fix: mouse unresponsive at boot when game controllers are plugged in
  ];

  networking.networkmanager.enable = true;
  time.timeZone = "America/Chicago";
}
