{ config, pkgs, lib, ... }:

let
  # Breeze SDDM theme with solid black background
  sddm-breeze-black = pkgs.stdenvNoCC.mkDerivation {
    pname = "sddm-breeze-black";
    version = "1.0";
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/share/sddm/themes/breeze
      cp -r ${pkgs.kdePackages.plasma-desktop}/share/sddm/themes/breeze/* $out/share/sddm/themes/breeze/
      chmod -R u+w $out/share/sddm/themes/breeze
      sed -i 's/type=image/type=color/' $out/share/sddm/themes/breeze/theme.conf
      sed -i 's/color=#1d99f3/color=#000000/' $out/share/sddm/themes/breeze/theme.conf
    '';
  };
in

{
  imports = [
    ../hardware/x870-hardware-configuration.nix
    ../modules/desktop.nix
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

  boot.kernelParams = [
    "nvidia_drm.modeset=1"
    "nvidia_drm.fbdev=1"
    "usbcore.autosuspend=-1"  # fix: mouse unresponsive at boot when game controllers are plugged in
  ];

  networking.networkmanager.enable = true;
  time.timeZone = "America/Chicago";

  # --- Display manager: SDDM (KDE's native DM; better Plasma + Wayland integration) ---
  # Switched from GDM to SDDM because KDE Plasma is now the primary DE
  # (PartyDeck requires KDE Plasma for KWin splitscreen tiling).
  services.xserver.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    theme = "breeze";
  };

  # --- Desktop environments / compositors ---
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # --- Hyprland / Wayland helpers ---
  environment.systemPackages = with pkgs; [
    xdg-desktop-portal-hyprland
    godot_4
    sddm-breeze-black
  ];

  # --- NVIDIA ---
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
