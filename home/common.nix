{ ... }:
{
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
