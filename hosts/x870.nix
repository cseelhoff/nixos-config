{ config, pkgs, self, ... }:

let
  edidFile = pkgs.runCommand "modified-edid" {
    name = "modified-edid";
    src = ../../firmware/edid/modified_edid.bin;   # ← adjusted path
  } ''
    mkdir -p $out/lib/firmware/edid
    cp $src $out/lib/firmware/edid/modified_edid.bin
  '';
in {
  imports = [
    ../hardware/x870-hardware-configuration.nix
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

  networking.networkmanager.enable = true;
  time.timeZone = "America/Chicago";

  boot.kernelParams = [
    "drm.edid_firmware=HDMI-A-2:edid/modified_edid.bin"
    "video=HDMI-A-2:3840x2160@60,e"
    "nvidia_drm.modeset=1"
    "nvidia_drm.fbdev=1"
  ];

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.nvidia = {
    modesetting.enable = true;
    open = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.beta;
  };

  hardware.firmware = [ edidFile ];
}