{ config, lib, pkgs, partydeck, ... }:

# Gaming module.
# Brings in Steam/Proton/gamescope/PartyDeck and — because PartyDeck's
# splitscreen tiling is implemented as a KWin script — the full KDE
# Plasma 6 desktop, SDDM (Plasma's native display manager), and a
# tweaked Breeze SDDM theme. These KDE bits are NOT needed by any
# other workflow on the system; they're imported transitively because
# of this single PartyDeck dependency.

let
  isNvidia = lib.elem "nvidia" (config.services.xserver.videoDrivers or []);

  partydeckPkg = partydeck.packages.x86_64-linux.default;

  # Start-menu entry for PartyDeck. The upstream package ships only the
  # binary, so we build a .desktop file with makeDesktopItem and merge
  # it into the package via symlinkJoin. KDE's kbuildsycoca6 picks this
  # up automatically because it lands in $out/share/applications and
  # the package is in environment.systemPackages (which gets exported
  # in XDG_DATA_DIRS).
  partydeckDesktop = pkgs.makeDesktopItem {
    name = "partydeck";
    desktopName = "PartyDeck";
    comment = "Split-screen game launcher";
    exec = "partydeck";
    icon = "partydeck";
    terminal = false;
    categories = [ "Game" ];
  };

  partydeckWithDesktop = pkgs.symlinkJoin {
    name = "partydeck-with-desktop";
    paths = [
      partydeckPkg
      partydeckDesktop
      # Icon: stick the upstream PNG into the hicolor theme so KDE finds it.
      (pkgs.runCommand "partydeck-icon" {} ''
        mkdir -p $out/share/icons/hicolor/512x512/apps
        cp ${partydeckPkg.src or partydeckPkg}/.github/assets/icon.png \
           $out/share/icons/hicolor/512x512/apps/partydeck.png 2>/dev/null || \
        echo "no upstream icon, skipping"
      '')
    ];
  };

  # Breeze SDDM theme with a solid black background.
  sddm-breeze-black = pkgs.stdenvNoCC.mkDerivation {
    pname = "sddm-breeze-black";
    version = "1.0";
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/share/sddm/themes/breeze
      cp -r ${pkgs.kdePackages.plasma-desktop}/share/sddm/themes/breeze/* $out/share/sddm/themes/breeze/
      chmod -R u+w $out/share/sddm/themes/breeze
      sed -i 's/type=image/type=color/' $out/share/sddm/themes/breeze/theme.conf
      sed -i 's/color=#1d99f3/color=#000000/' $out/share/sddm/themes/breeze/theme.conf
    '';
  };
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

  # ---------------------------------------------------------------------
  # PartyDeck dependency chain: KDE Plasma 6 (KWin script) + SDDM theme
  # ---------------------------------------------------------------------
  # KDE Plasma 6 — required for PartyDeck splitscreen tiling (KWin script).
  services.desktopManager.plasma6.enable = true;

  # X server stack — Plasma uses Wayland, but several KDE tools still
  # pull in X11 bits and SDDM-X provides fallback sessions.
  services.xserver.enable = true;

  # SDDM is Plasma's native display manager; we use it because Plasma
  # is already in the closure for PartyDeck.
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    theme = "breeze";
  };

  environment.systemPackages = with pkgs; [
    sddm-breeze-black
    gamescope
    mangohud
    protonup-qt
    lutris
    bottles
    wineWow64Packages.staging
    bubblewrap         # PartyDeck: sandboxing for controller isolation
    fuse-overlayfs     # PartyDeck: filesystem overlay for player profiles
    partydeckWithDesktop  # PartyDeck splitscreen launcher + .desktop entry
    godot_4            # game engine (TLS overlay applied above)
  ];

  # --- Goldberg Steam Emu (PartyDeck LAN multiplayer) ---
  # 47584      : Goldberg LAN broadcast
  # 8211       : Palworld UE5 P2P listen (dedicated/co-op join-by-IP)
  # 55555      : Nemirtingas Epic Emu (NEE) LAN lobby discovery broadcast
  networking.firewall.allowedUDPPorts = [ 47584 8211 55555 ];
  networking.firewall.allowedTCPPorts = [ 47584 ];

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
}
