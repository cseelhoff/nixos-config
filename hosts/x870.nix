{ config, pkgs, ... }:
{
  imports = [ ../hardware/x870-hardware-configuration.nix ];

  boot.loader = {
    systemd-boot = { enable = true; configurationLimit = 10; editor = false; };
    efi = { canTouchEfiVariables = true; efiSysMountPoint = "/boot"; };
    grub.enable = false;
  };

  networking.networkmanager.enable = true;
  time.timeZone = "America/Chicago";
  boot.kernelParams = [ "video=HDMI-A-2:3840x2160@60,e" ];
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    open = true;
    package = config.boot.kernelPackages.nvidiaPackages.beta;
  };
}