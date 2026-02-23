{ pkgs, omarchy-nix, ... }:
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;

    users.admin = {
      imports = [
        ./common.nix
        omarchy-nix.homeManagerModules.default
      ];
    };
  };
}
