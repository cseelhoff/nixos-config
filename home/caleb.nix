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
  # Patch the upstream `code-insiders` package to tolerate missing
  # ripgrep binary removal (some upstream releases lack that path).
  ciPkg = code-insiders.packages.${pkgs.stdenv.hostPlatform.system}.vscode-insider;
  ciPatched = ciPkg.overrideAttrs (old: {
    patchPhase = (if builtins.hasAttr "patchPhase" old then old.patchPhase else "") + ''
      rm -f resources/app/node_modules/@vscode/ripgrep/bin/rg || true
    '';
  });
in
{
  home-manager.users.caleb = {
    imports = [
      ./common.nix
    ];

    home.packages = lib.optionals hostIsGraphical [
      pkgs-unstable.onedriver  # OneDrive FUSE client (unstable for latest auth fixes)
      # VS Code Insiders from the `code-insiders` flake input — patched to
      # ignore missing ripgrep removal errors.
      ciPatched
      pkgs.grayjay            # Grayjay desktop media app (unfree)
    ];

    programs.git = {
      enable = true;
      settings.user.name = "cseelhoff";
      settings.user.email = "cseelhoff@gmail.com";
    };
  };
}

