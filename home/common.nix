{ lib, pkgs, ... }:
{
  home.pointerCursor = {
    name = "Adwaita";
    package = pkgs.adwaita-icon-theme;
    size = 24;
    gtk.enable = true;
    hyprcursor.enable = true;
  };

  # --- Dark mode globally ---
  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };
  };

  dconf.settings."org/gnome/desktop/interface" = {
    color-scheme = "prefer-dark";
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

  # ---------------------------------------------------------------------------
  # Hyprland – minimal, dark, NVIDIA-friendly
  # ---------------------------------------------------------------------------
  wayland.windowManager.hyprland = {
    enable = true;

    settings = {
      # ── NVIDIA / Wayland env ──
      env = [
        "GBM_BACKEND,nvidia-drm"
        "__GLX_VENDOR_LIBRARY_NAME,nvidia"
        "WLR_NO_HARDWARE_CURSORS,1"
        "XCURSOR_SIZE,24"
      ];

      # ── Monitor (auto-detect; override if needed) ──
      monitor = [ ",preferred,auto,1" ];

      # ── Input ──
      input = {
        follow_mouse = 1;
        mouse_refocus = false;
        sensitivity = 0;           # no acceleration
        accel_profile = "flat";
      };

      # ── Look & feel (dark, understated) ──
      general = {
        gaps_in = 4;
        gaps_out = 8;
        border_size = 2;
        "col.active_border" = "rgb(6699cc)";      # muted blue
        "col.inactive_border" = "rgb(333333)";     # dark grey
        layout = "dwindle";
      };

      decoration = {
        rounding = 6;
        blur.enabled = false;
        shadow.enabled = false;
      };

      animations.enabled = false;

      dwindle.preserve_split = true;

      misc = {
        force_default_wallpaper = 0;    # no anime girl
        disable_hyprland_logo = true;
        middle_click_paste = false;
        mouse_move_enables_dpms = false;
      };

      # ── Keybinds ──
      # SUPER as mod key
      "$mod" = "SUPER";

      bind = [
        # ── Launch ──
        "$mod, Return, exec, ghostty"
        "$mod, Space,  exec, fuzzel"
        "$mod, E,      exec, nautilus"             # file manager (GNOME)

        # ── Window management ──
        "$mod, Q,      killactive,"
        "$mod, F,      fullscreen, 0"
        "$mod, V,      togglefloating,"

        # ── Focus (vim-style + arrows) ──
        "$mod, Left,  movefocus, l"
        "$mod, Right, movefocus, r"
        "$mod, Up,    movefocus, u"
        "$mod, Down,  movefocus, d"

        # ── Move windows ──
        "$mod SHIFT, H, movewindow, l"
        "$mod SHIFT, L, movewindow, r"
        "$mod SHIFT, K, movewindow, u"
        "$mod SHIFT, J, movewindow, d"

        # ── Workspaces 1-5 ──
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"

        # ── Move window to workspace ──
        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"

        # ── Screenshots ──
        ", Print,       exec, grim -g \"$(slurp)\" - | wl-copy"   # region → clipboard
        "SHIFT, Print,  exec, grim - | wl-copy"                   # full screen → clipboard

        # ── Volume ──
        ", XF86AudioMute,        exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ", XF86AudioMicMute,     exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"

        # ── Media ──
        ", XF86AudioPlay,  exec, playerctl play-pause"
        ", XF86AudioNext,  exec, playerctl next"
        ", XF86AudioPrev,  exec, playerctl previous"

        # ── Session ──
        "$mod, L,      exec, loginctl lock-session" # lock screen
        "$mod SHIFT, E, exit,"                     # logout to GDM
      ];

      # ── Mouse binds ──
      bindm = [
        "$mod, mouse:272, movewindow"      # Super + LMB drag
        "$mod, mouse:273, resizewindow"    # Super + RMB drag
      ];

      # ── Volume (repeatable) ──
      binde = [
        ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
      ];

      # ── Autostart ──
      exec-once = [
        "hyprctl setcursor Adwaita 24"     # reset cursor from GDM
        "waybar"
        "mako"
        "nm-applet --indicator"            # NetworkManager tray icon
        "blueman-applet"                   # Bluetooth tray icon
      ];
    };
  };

  # ---------------------------------------------------------------------------
  # Fuzzel – fast Wayland app launcher
  # ---------------------------------------------------------------------------
  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        font = "Hack Nerd Font:size=13";
        dpi-aware = "no";
        prompt = "❯ ";
        terminal = "ghostty";
        layer = "overlay";
        lines = 12;
        width = 35;
        horizontal-pad = 16;
        vertical-pad = 8;
        inner-pad = 4;
      };
      colors = {
        background = "1a1a1add";
        text = "ccccccff";
        match = "6699ccff";
        selection = "333333ff";
        selection-text = "ffffffff";
        selection-match = "6699ccff";
        border = "6699ccff";
      };
      border = {
        width = 2;
        radius = 8;
      };
    };
  };

  # ---------------------------------------------------------------------------
  # Waybar – functional status bar
  # ---------------------------------------------------------------------------
  programs.waybar = {
    enable = true;
    settings = [{
      layer = "top";
      position = "top";
      height = 32;
      spacing = 8;

      modules-left   = [ "hyprland/workspaces" "hyprland/window" ];
      modules-center = [ "clock" ];
      modules-right  = [ "tray" "pulseaudio" "network" "bluetooth" "battery" ];

      "hyprland/workspaces" = {
        format = "{id}";
        on-click = "activate";
        persistent-workspaces."*" = 5;   # always show 5 workspaces
      };

      "hyprland/window" = {
        max-length = 40;
        separate-outputs = true;
      };

      clock = {
        format = "{:%a %b %d  %I:%M %p}";
        tooltip-format = "<tt>{calendar}</tt>";
      };

      pulseaudio = {
        format = "{icon} {volume}%";
        format-muted = "󰝟 muted";
        format-icons.default = [ "󰕿" "󰖀" "󰕾" ];
        on-click = "pavucontrol";
        on-click-right = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
      };

      network = {
        format-wifi = "󰤨 {essid}";
        format-ethernet = "󰈀 {ipaddr}/{cidr}";
        format-disconnected = "󰤭 offline";
        tooltip-format = "{ifname}: {ipaddr}/{cidr}\n{signalStrength}% signal";
        on-click = "nm-connection-editor";
      };

      bluetooth = {
        format = "󰂯 {status}";
        format-connected = "󰂱 {device_alias}";
        format-disabled = "";
        on-click = "blueman-manager";
        tooltip-format = "{controller_alias}\n{num_connections} connected";
      };

      tray = {
        icon-size = 18;
        spacing = 8;
      };

      battery = {
        format = "{icon} {capacity}%";
        format-icons = [ "󰁺" "󰁼" "󰁾" "󰂀" "󰂂" "󰁹" ];
        states = {
          warning = 30;
          critical = 15;
        };
      };
    }];

    style = ''
      * {
        font-family: "Hack Nerd Font";
        font-size: 13px;
        min-height: 0;
      }
      window#waybar {
        background: rgba(26, 26, 26, 0.92);
        color: #cccccc;
      }
      #workspaces button {
        padding: 0 6px;
        color: #888888;
        border-bottom: 2px solid transparent;
      }
      #workspaces button.active {
        color: #ffffff;
        border-bottom: 2px solid #6699cc;
      }
      #clock, #pulseaudio, #network, #bluetooth, #battery, #tray {
        padding: 0 10px;
      }
      #pulseaudio.muted {
        color: #cc6666;
      }
      #network.disconnected {
        color: #cc6666;
      }
      tooltip {
        background: #1a1a1a;
        border: 1px solid #333333;
        border-radius: 6px;
      }
    '';
  };

  home.stateVersion = "25.11";
}
