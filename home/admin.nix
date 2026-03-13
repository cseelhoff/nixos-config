{ pkgs, ... }:
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;

    users.admin = {
      imports = [
        ./common.nix
      ];
    };
  };
}
