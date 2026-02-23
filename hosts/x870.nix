{ config, pkgs, ... }:
{
  imports = [ ../hardware/x870-hardware-configuration.nix ];

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