{ pkgs, ... }:
{
  home-manager.users.caleb = {
    imports = [
      ./common.nix
    ];

    home.packages = [ pkgs.onedriver ];  # OneDrive FUSE client (run onedriver-launcher)

    programs.git = {
      enable = true;
      settings.user.name = "cseelhoff";
      settings.user.email = "cseelhoff@gmail.com";
    };
  };
}
