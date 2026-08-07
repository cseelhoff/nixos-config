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
  hostIsX870 = config.networking.hostName == "x870";
  # Patch the upstream `code-insiders` package to tolerate missing
  # ripgrep binary removal (some upstream releases lack that path).
  ciPkg = code-insiders.packages.${pkgs.stdenv.hostPlatform.system}.vscode-insider;
  ciPatched = ciPkg.overrideAttrs (old: {
    patchPhase = (if builtins.hasAttr "patchPhase" old then old.patchPhase else "") + ''
      rm -f resources/app/node_modules/@vscode/ripgrep/bin/rg || true
    '';
    preFixup = (if builtins.hasAttr "preFixup" old then old.preFixup else "") + ''
      vsceSignUnpacked="$out/lib/vscode/resources/app/node_modules.asar.unpacked/@vscode/vsce-sign/bin/vsce-sign"
      vsceSignMirror="$out/lib/vscode/resources/app/node_modules/@vscode/vsce-sign/bin/vsce-sign"
      if [ -e "$vsceSignUnpacked" ] && [ ! -e "$vsceSignMirror" ]; then
        mkdir -p "$(dirname "$vsceSignMirror")"
        cp "$vsceSignUnpacked" "$vsceSignMirror"
      fi
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

    # Own the launcher-compatible instance declaratively. The launcher creates
    # direct /nix/store unit links, which can become stale after a package
    # generation changes and leave the underlying mountpoint looking empty.
    systemd.user.services."onedriver@home-caleb-OneDrive" = lib.mkIf hostIsX870 {
      Unit.Description = "OneDrive mount";
      Service = {
        ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p %f";
        ExecStart = "${pkgs-unstable.onedriver}/bin/onedriver --log info %f";
        ExecStopPost = "/run/wrappers/bin/fusermount3 -uz /%I";
        Restart = "on-abnormal";
        RestartSec = 3;
        RestartForceExitStatus = 2;
      };
      Install.WantedBy = [ "default.target" ];
    };

    programs.zsh = {
      enable = true;
      # Add the Grok path
      initContent = ''
        export PATH="$HOME/.grok/bin:$PATH"
      '';
    };

    programs.git = {
      enable = true;
      settings.user.name = "cseelhoff";
      settings.user.email = "cseelhoff@gmail.com";
    };
  };
}

