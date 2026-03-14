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
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # KDE Plasma 6 – required for PartyDeck splitscreen tiling (KWin script)
  services.desktopManager.plasma6.enable = true;

  # --- File manager: Thunar ---
  programs.thunar = {
    enable = true;
    plugins = with pkgs.xfce; [
      thunar-archive-plugin
      thunar-volman
      thunar-media-tags-plugin
    ];
  };

  services.gvfs.enable = true;     # trash, remote mounts, MTP
  services.tumbler.enable = true;  # thumbnail generation

  # --- Hyprland / Wayland helpers ---
  environment.systemPackages = with pkgs; [
    ghostty            # terminal (configured in home/common.nix)
    fuzzel             # app launcher (Super+Space)
    waybar             # status bar
    bubblewrap         # PartyDeck: sandboxing for controller isolation
    fuse-overlayfs     # PartyDeck: filesystem overlay for player profiles
    mako               # notification daemon
    grim               # screenshot
    slurp              # region select
    wl-clipboard       # clipboard
    xdg-desktop-portal-hyprland
    networkmanagerapplet # nm-applet for waybar tray
    blueman            # bluetooth manager
    pavucontrol        # audio mixer
    playerctl          # media key control
    hyprlock           # lock screen (Super+L)
  ];

  # --- Bluetooth ---
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

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
