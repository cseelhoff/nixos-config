{ config, pkgs, lib, ... }:

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
  ];

  # Fix Godot TLS: nixpkgs build passes "False" for the CA bundle path
  environment.variables.SSL_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt";

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
