{ pkgs, ... }:
{
  home-manager.users.caleb = {
    imports = [
      ./common.nix
    ];

    programs.git = {
      enable = true;
      settings.user.name = "cseelhoff";
      settings.user.email = "cseelhoff@gmail.com";
    };
  };
}
