{ config, pkgs, ... }:

{
  # Enable Steam + Proton (handles 32-bit libs, Vulkan, etc.)
  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;  # Wayland/Hyprland scaling/perf
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;

    # Custom Protons (GE is a must for max compat)
    extraCompatPackages = with pkgs; [
      proton-ge-bin
      # Add more via flake inputs if needed
    ];
  };

  # Gamemode for CPU/GPU boosts
  programs.gamemode.enable = true;

  # Essential gaming helpers
  environment.systemPackages = with pkgs; [
    gamescope
    bubblewrap
    fuse-overlayfs      # For Proton's containerized compatibility layers
    SDL2
    pkg-config
    openssl
    libarchive
    mangohud           # FPS overlay (Shift_L + F1)
    protonup-qt        # GUI for Proton-GE/Experimental installs
    lutris             # Non-Steam games (Wine/Proton)
    bottles            # Wine prefix manager
    wineWowPackages.staging  # Plain Wine (staging = good balance)
    # p7zip unzip unrar  # From your earlier archivers, if you want them here
  ];

  
  # Ensure Wayland/Hyprland basics are set (you probably already have this)
  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ ];

  # Unfree for NVIDIA/Steam blobs
  nixpkgs.config.allowUnfree = true;

  # Modern graphics config (matches your host's NVIDIA setup)
  hardware.graphics = {
    enable = true;
    enable32Bit = true;  # Already set in host, but redundant OK here or remove if duplicate
  };
}
