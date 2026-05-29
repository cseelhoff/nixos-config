{ config, lib, pkgs, ... }:

# GUI host module: lightweight Hyprland desktop.
#
# Provides graphics stack, fonts, GUI apps, file manager, bluetooth,
# the Hyprland Wayland compositor + ecosystem (waybar/fuzzel/mako/grim/
# slurp/hyprlock/wl-clipboard/playerctl), and a minimal greetd display
# manager.
#
# Display manager note: hosts that also import modules/gaming.nix will
# get KDE/SDDM from there instead — the greetd config below is
# automatically suppressed when SDDM is enabled (see lib.mkIf).
#
# Effects (blur, shadows, rounding, animations) are disabled in
# home/hyprland.nix so the desktop stays snappy on low-end hardware
# and over Proxmox VNC.

{
  # ---------------------------------------------------------------------
  # Graphics, fonts, GUI apps
  # ---------------------------------------------------------------------
  hardware.graphics.enable = true;

  fonts.fontconfig = {
    defaultFonts.monospace = [ "Hack Nerd Font Mono" ];
    antialias = true;
    hinting.enable = true;
    hinting.style = "full";
    subpixel.rgba = "none";
  };
  fonts.packages = with pkgs; [ nerd-fonts.hack ];

  environment.systemPackages = with pkgs; [
    pavucontrol        # audio mixer
    blueman            # bluetooth manager (GUI)
    brave
    vscode
    obsidian
    fsearch            # fast file search (GTK)
    localsend          # LAN file sharing (LocalSend)

    # Hyprland ecosystem
    xdg-desktop-portal-hyprland
    fuzzel             # app launcher (Super+Space)
    waybar             # status bar
    mako               # notification daemon
    grim               # screenshot
    slurp              # region select
    wl-clipboard       # clipboard
    networkmanagerapplet # nm-applet for waybar tray
    playerctl          # media key control
    hyprlock           # lock screen (Super+L)
  ];

  # LocalSend: open TCP+UDP 53317 on all interfaces.
  networking.firewall.allowedTCPPorts = [ 53317 ];
  networking.firewall.allowedUDPPorts = [ 53317 ];

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

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # Cap user-level systemd stop timeout to avoid the "A stop job is
  # running for User Manager for UID …" delay on reboot/shutdown when
  # heavy session services hang on SIGTERM. Default is ~90s; cap at 30s.
  systemd.user.extraConfig = ''
    DefaultTimeoutStopSec=30s
  '';

  xdg.portal = {
    enable = true;
    # Hyprland portal handles screencast/global-shortcuts/window-picking
    # via wlroots; GTK portal handles FileChooser, AppChooser, Print,
    # Settings, etc. The KDE portal is auto-injected by
    # services.desktopManager.plasma6 (in modules/gaming.nix) so it
    # doesn't need to be listed here — but we explicitly route
    # FileChooser AWAY from it below, because the KDE backend in
    # current nixpkgs sometimes fails to register that interface and
    # apps die with "No such interface org.freedesktop.portal.FileChooser".
    extraPortals = [
      pkgs.xdg-desktop-portal-hyprland
      pkgs.xdg-desktop-portal-gtk
    ];
    # Per-desktop routing. Keys match XDG_CURRENT_DESKTOP; `common` is
    # the fallback. SDDM (from modules/gaming.nix) offers both Plasma
    # and Hyprland sessions, so both desktops are configured here.
    # FileChooser is forced to the GTK backend everywhere — the KDE
    # backend in current nixpkgs has a habit of failing to register
    # the interface, producing "No such interface
    # org.freedesktop.portal.FileChooser" for any app that asks for it.
    config = {
      hyprland = {
        default = [ "hyprland" "gtk" ];
        "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
      };
      kde = {
        default = [ "kde" "gtk" ];
        "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
      };
      common = {
        default = [ "gtk" ];
      };
    };
  };

  # ---------------------------------------------------------------------
  # Hyprland compositor
  # ---------------------------------------------------------------------
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # ---------------------------------------------------------------------
  # Display manager: greetd + tuigreet (lightweight, ~10 MB).
  # Auto-suppressed when SDDM is enabled (modules/gaming.nix activates
  # SDDM because KDE is its native DM).
  # ---------------------------------------------------------------------
  services.greetd = lib.mkIf (!config.services.displayManager.sddm.enable) {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --remember --cmd Hyprland";
        user = "greeter";
      };
    };
  };
}
