{ config, lib, pkgs, partydeck, ... }:

let
  isNvidia = lib.elem "nvidia" (config.services.xserver.videoDrivers or []);
in
{
  # Fix Godot TLS: nixpkgs build omits system_certs_path, causing
  # "Cannot open X509CertificateMbedTLS file 'False'" on NixOS.
  nixpkgs.overlays = [
    (final: prev: {
      godot_4 = prev.godot_4.overrideAttrs (old: {
        sconsFlags = (old.sconsFlags or []) ++ [
          "system_certs_path=/etc/ssl/certs/ca-certificates.crt"
        ];
      });
    })
  ];

  # --- Goldberg Steam Emu (PartyDeck LAN multiplayer) ---
  networking.firewall.allowedUDPPorts = [ 47584 ];
  networking.firewall.allowedTCPPorts = [ 47584 ];

  # KDE Plasma 6 – required for PartyDeck splitscreen tiling (KWin script)
  services.desktopManager.plasma6.enable = true;

  # Steam + Proton
  programs.steam = {
    enable = true;
    gamescopeSession = {
      enable = true;                       # SDDM "Steam" Wayland session
      args = [
        "--output-width" "3840"
        "--output-height" "2160"
        "--nested-refresh" "60"
        "--adaptive-sync"
        "--expose-wayland"
        "--force-grab-cursor"
        "-e"                               # steam overlay integration
      ];
      # NVIDIA-only Wayland compat env. Empty on AMD/Intel/virtio-gpu.
      env = lib.mkIf isNvidia {
        GBM_BACKEND               = "nvidia-drm";
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
        WLR_NO_HARDWARE_CURSORS   = "1";
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
    partydeck.packages.x86_64-linux.default  # PartyDeck splitscreen launcher
    godot_4            # game engine (TLS overlay applied above)
  ];
}
