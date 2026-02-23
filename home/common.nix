{ lib, ... }:
{
  # Override omarchy's base16 color scheme with the Midnight theme palette
  # https://github.com/JaxonWright/omarchy-midnight-theme
  colorScheme = lib.mkForce {
    slug = "midnight";
    name = "Midnight";
    author = "JaxonWright";
    palette = {
      base00 = "000000"; # background — pure OLED black
      base01 = "0D0D0D"; # lighter background
      base02 = "1E1E1E"; # selection / surface
      base03 = "333333"; # comments / muted
      base04 = "8A8A8D"; # dark foreground
      base05 = "EFEFEF"; # main foreground
      base06 = "EAEAEA"; # light foreground
      base07 = "FFFFFF"; # brightest white
      base08 = "D35F5F"; # red
      base09 = "F59E0B"; # orange
      base0A = "FFC107"; # yellow
      base0B = "8A9A7B"; # green
      base0C = "88AABB"; # cyan
      base0D = "407E70"; # teal accent
      base0E = "C1A1C1"; # magenta
      base0F = "B91C1C"; # dark red
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
  };

  home.stateVersion = "25.11";
}
