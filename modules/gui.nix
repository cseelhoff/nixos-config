{ pkgs, ... }:

{
  # --- Desktop environment helpers ---
  # ghostty is configured via home-manager in home/hyprland.nix and
  # installed there — no need to add it as a system package.
  environment.systemPackages = with pkgs; [
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

    # GUI apps (desktop-only — not needed on WSL/headless hosts)
    brave
    vscode
    obsidian
  ];

  # Graphics stack — needed for any Wayland/X compositor.
  # (NVIDIA hosts also enable enable32Bit via modules/nvidia.nix.)
  hardware.graphics.enable = true;

  # Fonts only matter on hosts with a display.
  fonts.fontconfig = {
    defaultFonts.monospace = [ "Hack Nerd Font Mono" ];
    antialias = true;
    hinting.enable = true;
    hinting.style = "full";
    subpixel.rgba = "none";
  };
  fonts.packages = with pkgs; [ nerd-fonts.hack ];

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
