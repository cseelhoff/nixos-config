{ config, pkgs, ... }:
{
  imports = [ ../hardware/desktop-hardware-configuration.nix ];

  boot.loader = {
    systemd-boot = { enable = true; configurationLimit = 10; editor = false; };
    efi = { canTouchEfiVariables = true; efiSysMountPoint = "/boot"; };
    grub.enable = false;
  };

  networking.networkmanager.enable = true;
  services.xserver.xkb.layout = "us";
}