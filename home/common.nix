{ lib, ... }:
{
  # Override omarchy's base16 color scheme with the Midnight theme palette
  # https://github.com/JaxonWright/omarchy-midnight-theme
  colorScheme = lib.mkForce {
    slug = "vintage-light";
    name = "Vintage-light";
    author = "Caleb Seelhoff";
    palette = {
      base00 = "020202"; # background / black
      base01 = "555555"; # lighter background (brightBlack)
      base02 = "FFFFFF"; # selection background
      base03 = "555555"; # comments / muted (brightBlack)
      base04 = "C0C0C0"; # dark foreground (white/foreground)
      base05 = "C0C0C0"; # main foreground
      base06 = "C0C0C0"; # light foreground
      base07 = "FFFFFF"; # brightest white
      base08 = "E00000"; # red
      base09 = "FF8080"; # bright red (orange slot)
      base0A = "C0C000"; # yellow
      base0B = "00C000"; # green
      base0C = "00C0C0"; # cyan
      base0D = "0000FF"; # blue
      base0E = "C000C0"; # purple
      base0F = "C0C000"; # yellow (dark accent)
    };
  };

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
    ghostty = {
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
        minimum-contrast = 2;  # or 3 for stronger boost
      };
    };
  };

  # wayland.windowManager.hyprland.settings = {
  #   input = {
  #     touchpad = {
  #       middle_button_emulation = false;
  #     };
  #     follow_mouse = 1;
  #     mouse_refocus = false;
  #   };

  #   misc = {
  #     middle_click_paste = false;
  #     force_default_wallpaper = 0;
  #     mouse_move_enables_dpms = false;
  #   };

  #   env = [
  #     "WLR_NO_HARDWARE_CURSORS,1"
  #   ];
  # };

  home.stateVersion = "25.11";
}
