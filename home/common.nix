{ lib, pkgs, config, osConfig ? null, ... }:

let
  hostIsGraphical = osConfig.programs.hyprland.enable or false;
in
{
  # GUI/Hyprland-specific home config is only loaded on hosts that
  # actually run Hyprland (skipped on WSL/headless hosts).
  imports = lib.optionals hostIsGraphical [ ./hyprland.nix ];

  programs = {
    bat.enable = true;
    eza = { enable = true; enableZshIntegration = true; git = true; };
    fzf.enable = true;
    zoxide = { enable = true; options = [ "--cmd" "cd" ]; };
    zsh = {
      enable = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      oh-my-zsh = {
        enable = true;
        theme = "risto";
        plugins = [ "git" "history" "zoxide" ];
      };
    };
    neovim = { enable = true; defaultEditor = true; viAlias = true; withPython3 = true; };

    # Ghostty: GUI terminal, but its config is WM-agnostic.
    # Only enable on graphical hosts — WSL/headless don't have a display.
    ghostty = lib.mkIf hostIsGraphical {
      enable = true;
      themes = {
        vintage-light = {
          palette = [
            "0=#000000"
            "1=#E00000"
            "2=#00C000"
            "3=#C0C000"
            "4=#0000FF"
            "5=#C000C0"
            "6=#00C0C0"
            "7=#C0C0C0"
            "8=#555555"
            "9=#FF8080"
            "10=#80FF80"
            "11=#FFFF80"
            "12=#8080FF"
            "13=#FF80FF"
            "14=#80FFFF"
            "15=#FFFFFF"
          ];
          background = "#000000";
          foreground = "#C0C0C0";
          cursor-color = "#FFFFFF";
          selection-background = "#FFFFFF";
        };
      };
      settings = {
        theme = "vintage-light";
        #minimum-contrast = 2;  # or 3 for stronger boost
      };
    };
  };

  home.stateVersion = "25.11";
}
