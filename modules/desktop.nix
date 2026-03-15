{ pkgs, ... }:

{
  # --- Desktop environment helpers ---
  environment.systemPackages = with pkgs; [
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

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };
}
