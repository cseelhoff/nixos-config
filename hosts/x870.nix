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
  services.desktopManager.gnome.enable = true;

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # --- Hyprland / Wayland helpers ---
  environment.systemPackages = with pkgs; [
    ghostty            # default Hyprland terminal (configured in home/common.nix)
    wofi               # app launcher
    waybar             # status bar
    mako               # notification daemon
    grim               # screenshot
    slurp              # region select
    wl-clipboard       # clipboard
    xdg-desktop-portal-hyprland
  ];

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  # --- NVIDIA (minimal gaming config) ---
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
