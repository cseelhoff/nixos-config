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

  # --- Display manager: SDDM (KDE's native DM; better Plasma + Wayland integration) ---
  # Switched from GDM to SDDM because KDE Plasma is now the primary DE
  # (PartyDeck requires KDE Plasma for KWin splitscreen tiling).
  services.xserver.enable = true;
  # services.xserver.videoDrivers is set by ../modules/nvidia.nix

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
    sddm-breeze-black
  ];

  # NVIDIA driver config moved to ../modules/nvidia.nix
}
