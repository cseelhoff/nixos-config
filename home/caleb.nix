{ pkgs, lib, config, code-insiders, nixpkgs-unstable, ... }:
let
  # Cherry-picked packages from nixos-unstable. Build a fresh pkgs set keyed
  # to this host's system so we can pull individual newer packages without
  # moving the whole system off stable.
  pkgs-unstable = import nixpkgs-unstable {
    inherit (pkgs.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  };
  # Graphical-only packages are skipped on headless hosts (WSL).
  # WSL drives VS Code from the Windows side; the Linux vscode-insiders
  # binary isn't needed there because Windows pushes the server payload
  # into ~/.vscode-server-insiders/ (autoPatchelf'd via nixos-vscode-server).
  hostIsGraphical = config.programs.hyprland.enable or false;
in
{
  home-manager.users.caleb = {
    imports = [
      ./common.nix
    ];

    home.packages = lib.optionals hostIsGraphical [
      pkgs-unstable.onedriver  # OneDrive FUSE client (unstable for latest auth fixes)
      # VS Code Insiders from the `code-insiders` flake input — auto-updated
      # daily upstream. Run `nix flake update code-insiders` to pull the
      # latest build, then rebuild. (nixpkgs-unstable's `vscode-insiders`
      # attr is gone as of the 2026-05 channel bump.)
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

