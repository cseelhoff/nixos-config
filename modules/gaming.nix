{ config, pkgs, ... }:

{
  # --- Goldberg Steam Emu (PartyDeck LAN multiplayer) ---
  networking.firewall.allowedUDPPorts = [ 47584 ];
  networking.firewall.allowedTCPPorts = [ 47584 ];

  # KDE Plasma 6 – required for PartyDeck splitscreen tiling (KWin script)
  services.desktopManager.plasma6.enable = true;

  # Steam + Proton
  programs.steam = {
    enable = true;
    gamescopeSession = {
      enable = true;                       # GDM "Steam" Wayland session
      args = [
        "--output-width" "3840"
        "--output-height" "2160"
        "--nested-refresh" "60"
        "--adaptive-sync"
        "--expose-wayland"
        "--force-grab-cursor"
        "-e"                               # steam overlay integration
      ];
      env = {
        # NVIDIA Wayland compat (same as Hyprland session)
        GBM_BACKEND            = "nvidia-drm";
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
        WLR_NO_HARDWARE_CURSORS = "1";
      };
    };
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    extraCompatPackages = with pkgs; [
      proton-ge-bin
    ];
  };

  # gamescope needs CAP_SYS_NICE for proper scheduling
  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };

  # CPU/GPU performance boosts while gaming
  programs.gamemode.enable = true;

  # Gaming tools
  environment.systemPackages = with pkgs; [
    gamescope
    mangohud
    protonup-qt
    lutris
    bottles
    wineWowPackages.staging
    bubblewrap         # PartyDeck: sandboxing for controller isolation
    fuse-overlayfs     # PartyDeck: filesystem overlay for player profiles
  ];
}
