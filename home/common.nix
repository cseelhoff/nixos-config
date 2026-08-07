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
    neovim = { enable = true; defaultEditor = true; viAlias = true; withPython3 = true; withRuby = false; };

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
        scrollback-limit = 100000000;  # ~100 MB per surface (default ~10 MB), in bytes
      };
    };
  };

  # User MIME choices outrank /etc/xdg/mimeapps.list. Remove stale Dolphin
  # entries without taking ownership of the whole file, so every unrelated
  # user-selected default survives.
  home.activation.defaultFileManager = lib.mkIf hostIsGraphical (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mimeApps="''${XDG_CONFIG_HOME:-$HOME/.config}/mimeapps.list"
      if [[ -L "$mimeApps" ]]; then
        mimeApps="$(${pkgs.coreutils}/bin/readlink -f "$mimeApps")"
      fi
      if [[ -f "$mimeApps" ]]; then
        $DRY_RUN_CMD ${pkgs.gnused}/bin/sed --in-place --regexp-extended \
          --expression='s/org\.kde\.dolphin\.desktop;?//g' \
          --expression='/^inode\/directory=$/d' \
          "$mimeApps"
      fi

      $DRY_RUN_CMD ${pkgs.coreutils}/bin/env \
        XDG_CURRENT_DESKTOP=X-Generic \
        KDE_FULL_SESSION= \
        KDE_SESSION_VERSION=0 \
        DESKTOP_SESSION= \
        ${pkgs.xdg-utils}/bin/xdg-mime default thunar.desktop inode/directory
    ''
  );

  home.stateVersion = "25.11";
}
