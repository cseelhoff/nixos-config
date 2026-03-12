{ config, pkgs, self, ... }:  # ← Add self here (now available via specialArgs)

let
  # Copy the EDID file into the Nix store and reference it
  edidPath = self + /edid/modified_edid.bin;

  edidFile = pkgs.runCommand "modified-edid" {
    name = "modified-edid";
    neededForBoot = true;
  } ''
    mkdir -p $out/lib/firmware/edid
    cp ${edidPath} $out/lib/firmware/edid/modified_edid.bin
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

  # Custom EDID in firmware (early loading via neededForBoot)
  hardware.firmware = [ edidFile ];
}