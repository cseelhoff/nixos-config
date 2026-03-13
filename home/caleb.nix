{ pkgs, ... }:
{
  home-manager.users.caleb = {
    imports = [
      ./common.nix
    ];
  };
}
