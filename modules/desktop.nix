{ pkgs, ... }:

{
  # --- Desktop environment helpers ---
  environment.systemPackages = with pkgs; [
    onedriver          # OneDrive FUSE client (run onedriver-launcher for GUI)
    ghostty            # terminal (configured in home/common.nix)
    fuzzel             # app launcher (Super+Space)
    waybar             # status bar
    mako               # notification daemon
    grim               # screenshot
    slurp              # region select
    wl-clipboard       # clipboard
    networkmanagerapplet # nm-applet for waybar tray
    blueman            # bluetooth manager
    pavucontrol        # audio mixer
    playerctl          # media key control
    hyprlock           # lock screen (Super+L)
  ];

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

  # --- Bluetooth ---
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # Shorten the user-level systemd stop timeout to avoid the
  # "A stop job is running for User Manager for UID …" delay on
  # reboot/shutdown.  Plasma Wayland services (plasmashell, kwin_wayland,
  # kded6, etc.) sometimes hang on SIGTERM; this caps the wait at 15 s
  # instead of the default ~90 s.
  systemd.user.extraConfig = ''
    DefaultTimeoutStopSec=30s
  '';

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };
}
