{ pkgs, omarchy-nix, ... }:
{
  home-manager.users.caleb = {
    imports = [
      ./common.nix
      omarchy-nix.homeManagerModules.default
    ];
  };
}
