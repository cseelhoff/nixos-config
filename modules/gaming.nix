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
      # Add more via flake inputs if needed (see below)
    ];
  };

  # Gamemode for CPU/GPU boosts
  programs.gamemode.enable = true;

  # Essential gaming helpers
  environment.systemPackages = with pkgs; [
    mangohud           # FPS overlay (Shift_L + F1)
    protonup-qt        # GUI for Proton-GE/Experimental installs
    lutris             # Non-Steam games (Wine/Proton)
    bottles            # Wine prefix manager
    wineWowPackages.staging  # Plain Wine (staging = good balance)
    # p7zip unzip unrar  # From your earlier archivers
  ];

  # Unfree for NVIDIA/Steam blobs
  nixpkgs.config.allowUnfree = true;

  # Extra NVIDIA tweaks for gaming (builds on your host config)
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };
}

