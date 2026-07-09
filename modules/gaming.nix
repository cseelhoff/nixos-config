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

  # PINCE (Cheat-Engine-alike memory scanner) ships as an AppImage at
  # ~/PINCE.AppImage. It needs root for ptrace and, when launched as root
  # under Wayland, the session's display env passed through. This folds the
  # whole `sudo env … appimage-run` incantation into a single `pince`
  # command; the appimage-run referenced here already carries zstd via the
  # overlay above. Optional arg overrides the default AppImage path.
  pince = pkgs.writeShellScriptBin "pince" ''
    exec sudo env \
      HOME="$HOME" \
      XDG_RUNTIME_DIR="/run/user/$(id -u)" \
      WAYLAND_DISPLAY="$WAYLAND_DISPLAY" \
      QT_QPA_PLATFORM=wayland \
      ${pkgs.appimage-run}/bin/appimage-run \
      "''${1:-$HOME/PINCE.AppImage}"
  '';

  # --- Per-pad gamepad -> keyboard/mouse bridge (PartyDeck 4-player KBM) ---
  # PartyDeck grabs ONE input device per split-screen instance. Keyboard/mouse-
  # only games (Neverwinter Nights: EE) read no gamepad, and every shared
  # virtual-input tool (antimicrox, input-remapper, Steam Input) exposes a
  # SINGLE global keyboard+mouse that cannot be routed to one instance. This
  # bridge runs one process per physical pad, each creating its OWN virtual
  # keyboard+mouse (mouse buttons + relative motion + mapped keys, but NO
  # gamepad buttons, so PartyDeck classifies it as a mouse). N pads yield N
  # distinct devices, one assignable per player. The script itself lives in
  # scripts/partydeck_pad_bridge.py; edit the key map there.
  padBridgePython = pkgs.python3.withPackages (ps: [ ps.evdev ]);

  padBridge = pkgs.writeShellScriptBin "partydeck-pad-bridge" ''
    exec ${padBridgePython}/bin/python3 ${../scripts/partydeck_pad_bridge.py} "$@"
  '';

  # Start one bridge per connected pad and kill them all on exit. Run this
  # before opening PartyDeck's instance screen, then assign each resulting
  # 'partydeck-kbm-pN' device to a player.
  padBridgeAll = pkgs.writeShellScriptBin "partydeck-pad-bridge-all" ''
    set -u
    pids=()
    cleanup() { [ ''${#pids[@]} -gt 0 ] && kill "''${pids[@]}" 2>/dev/null || true; }
    trap cleanup EXIT INT TERM
    i=0
    for link in /dev/input/by-id/*-event-joystick; do
      [ -e "$link" ] || continue
      i=$((i + 1))
      dev=$(readlink -f "$link")
      echo "pad $i -> $dev"
      ${padBridge}/bin/partydeck-pad-bridge --device "$dev" --name "partydeck-kbm-p$i" &
      pids+=($!)
    done
    if [ "$i" -eq 0 ]; then
      echo "no gamepads found under /dev/input/by-id/*-event-joystick" >&2
      exit 1
    fi
    echo "started $i pad bridge(s); press Ctrl-C to stop"
    wait
  '';
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

      # Bake libzstd into appimage-run's FHS sandbox. Some AppImages
      # (e.g. ~/PINCE.AppImage) pull in libzstd.so at runtime; the default
      # appimage-run env omits it, so without this every call needs a
      # per-invocation `.override { extraPkgs = p: [ p.zstd ]; }`.
      appimage-run = prev.appimage-run.override {
        extraPkgs = p: [ p.zstd ];
      };
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
    heroic             # native GOG Galaxy / Epic / Amazon library launcher
    antimicrox         # map keyboard/mouse controls to a gamepad
    padBridge          # partydeck-pad-bridge: one pad -> one virtual kbd/mouse
    padBridgeAll       # partydeck-pad-bridge-all: launch one bridge per pad
    wineWow64Packages.staging
    bubblewrap         # PartyDeck: sandboxing for controller isolation
    fuse-overlayfs     # PartyDeck: filesystem overlay for player profiles
    partydeckWithDesktop  # PartyDeck splitscreen launcher + .desktop entry
    godot_4            # game engine (TLS overlay applied above)
    appimage-run       # run AppImages in an FHS sandbox (zstd baked in via overlay)
    pince              # `pince [path]` = sudo + Wayland env + appimage-run wrapper
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

  # --- Per-pad KBM bridge: /dev/uinput access (see padBridge in the let block) ---
  # The bridge runs as the interactive user and creates virtual input devices
  # via /dev/uinput, which is root-only by default. Grant the `input` group
  # read/write on it and put the user in that group (this mirrors PartyDeck's
  # own "add your user to the input group" guidance for reading the pads too).
  # NOTE: log out and back in once after switching so the graphical session
  # actually picks up the new supplementary group.
  users.users.caleb.extraGroups = [ "input" ];
  boot.kernelModules = [ "uinput" ];
  services.udev.extraRules = ''
    KERNEL=="uinput", SUBSYSTEM=="misc", GROUP="input", MODE="0660", OPTIONS+="static_node=uinput"
  '';

  # ---------------------------------------------------------------------
  # nix-ld libraries for prebuilt (GOG/Heroic) native Linux games
  # ---------------------------------------------------------------------
  # Heroic installs unpatched, FHS-linked ELF binaries (e.g. Neverwinter
  # Nights: EE's game/bin/linux-x86/nwmain-linux). Their ELF interpreter
  # is /lib64/ld-linux-x86-64.so.2, which on NixOS is the nix-ld shim
  # (enabled in modules/vscode-tunnel.nix). nix-ld only resolves libraries
  # listed in programs.nix-ld.libraries, and the tunnel module's set is
  # scoped to the VS Code CLI — so the game's loader couldn't find
  # libGL.so.1 and bailed with "cannot open shared object file". These
  # entries add the graphics/audio stack those games need so the launcher
  # script runs directly (no steam-run wrapper required).
  # programs.nix-ld.libraries is a list option, so this MERGES with the
  # tunnel module's definition rather than overriding it.
  programs.nix-ld = {
    enable = lib.mkDefault true;
    libraries = with pkgs; [
      libGL             # libGL.so.1 — the missing lib that blocked nwmain-linux
      openal            # libopenal.so.1
      stdenv.cc.cc.lib  # libstdc++.so.6
      alsa-lib          # openal-soft dlopens libasound.so.2 at runtime
      libpulseaudio     # openal-soft dlopens libpulse.so.0 at runtime
    ];
  };
}
