{ pkgs, code-insiders, nixpkgs-unstable, ... }:
let
  # Cherry-picked packages from nixos-unstable. Build a fresh pkgs set keyed
  # to this host's system so we can pull individual newer packages without
  # moving the whole system off stable.
  pkgs-unstable = import nixpkgs-unstable {
    inherit (pkgs.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  };
in
{
  home-manager.users.caleb = {
    imports = [
      ./common.nix
    ];

    home.packages = [
      pkgs-unstable.onedriver  # OneDrive FUSE client (unstable for latest auth fixes)
      code-insiders.packages.${pkgs.stdenv.hostPlatform.system}.vscode-insider
      pkgs.grayjay            # Grayjay desktop media app (unfree)
    ];

    programs.git = {
      enable = true;
      settings.user.name = "cseelhoff";
      settings.user.email = "cseelhoff@gmail.com";
    };
  };
}
