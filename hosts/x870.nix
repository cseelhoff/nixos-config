{ config, pkgs, lib, ... }:

{
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

  # === LG C2 OLED EDID FORCE-RGB FIX (this is the important part) ===
  # This makes the custom EDID available in the initrd so it loads from GRUB onward
  hardware.display.edid.packages = [
    (pkgs.runCommand "lg-c2-forced-rgb" {} ''
      mkdir -p $out/lib/firmware/edid
      cp ${../firmware/edid/modified_edid.bin} $out/lib/firmware/edid/modified_edid.bin
    '')
  ];

  boot.kernelParams = [
    "drm.edid_firmware=HDMI-A-2:edid/modified_edid.bin"
    "video=HDMI-A-2:3840x2160@60,e"
    "nvidia_drm.modeset=1"
    "nvidia_drm.fbdev=1"
  ];

  # Disable omarchy's greetd (hardcoded to Hyprland) so SDDM can manage sessions
  services.greetd.enable = lib.mkForce false;

  services.xserver = {
    enable = true;
    videoDrivers = [ "nvidia" ];
  };

  # SDDM display manager (offers Wayland / X11 session selection at login)
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  # Desktop environments with X11 session support
  services.desktopManager.plasma6.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # Resolve conflict between Plasma 6 (ksshaskpass) and GNOME (seahorse)
  programs.ssh.askPassword = lib.mkForce "${pkgs.kdePackages.ksshaskpass}/bin/ksshaskpass";

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
}
