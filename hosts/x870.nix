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

  # === LG C2 OLED EDID FORCE-RGB FIX (kernel part you already have) ===
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

    # Force NVIDIA X11 driver to use RGB Full range with custom EDID
    deviceSection = ''
      Option "CustomEDID" "HDMI-0:/run/current-system/firmware/edid/modified_edid.bin"
      Option "ColorRange" "Full"
      Option "ColorFormat" "RGB"
      Option "UseEdid" "TRUE"
      Option "ModeValidation" "AllowNonEdidModes"
    '';

    screenSection = ''
      Option "ColorSpace" "RGB"
      Option "ColorRange" "Full"
    '';
  };

  # SDDM display manager (offers Wayland / X11 session selection at login)
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = false;
  };

  # Desktop environments
  services.desktopManager.plasma6.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # Force GNOME to X11 — NVIDIA Wayland ignores RGB/color overrides
  services.xserver.displayManager.gdm.wayland = false;

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
