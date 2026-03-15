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
  ];

  networking.networkmanager.enable = true;
  time.timeZone = "America/Chicago";

  # --- Display manager: GDM (supports GNOME, Hyprland, and gamescope sessions) ---
  services.xserver.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];

  services.displayManager.gdm = {
    enable = true;
    wayland = true;
  };

  # --- Desktop environments / compositors ---
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # --- Hyprland / Wayland helpers ---
  environment.systemPackages = with pkgs; [
    xdg-desktop-portal-hyprland
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
