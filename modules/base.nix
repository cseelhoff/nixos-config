{ pkgs, lib, home-manager, ... }:
{
  imports = [
    home-manager.nixosModules.home-manager
    ../home/admin.nix
    ../home/caleb.nix
  ];

  home-manager.backupFileExtension = "hm-backup";
  home-manager.overwriteBackup = true;

  # Create /bin/bash symlink for scripts with #!/bin/bash shebangs
  system.activationScripts.binbash = ''
    ln -sf ${pkgs.bash}/bin/bash /bin/bash
  '';

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;
  # NOTE: cudaSupport intentionally NOT set here — it would force CUDA
  # rebuilds on every host. Hosts with NVIDIA hardware should import
  # ../modules/nvidia.nix, which enables it.

  # Overlay: bump onedriver to v0.15.0 (fixes AADSTS70000 / invalid_grant auth bug)
  nixpkgs.overlays = [
    # Fix Godot TLS: nixpkgs build omits system_certs_path, causing
    # "Cannot open X509CertificateMbedTLS file 'False'" on NixOS
    (final: prev: {
      godot_4 = prev.godot_4.overrideAttrs (old: {
        sconsFlags = (old.sconsFlags or []) ++ [
          "system_certs_path=/etc/ssl/certs/ca-certificates.crt"
        ];
      });
    })
    (final: prev: {
      onedriver = prev.onedriver.overrideAttrs (newAttrs: oldAttrs: {
        version = "0.15.0";
        src = prev.fetchFromGitHub {
          inherit (oldAttrs.src) owner repo;
          rev = "v${newAttrs.version}";
          hash = "sha256-DCxF52CtA9KAP+yz5Rgzc/nUAXtZwfYAVU7oHREJlRY=";
        };
        vendorHash = "sha256-Ifcmf9AtZnrjgTPQnof/ap0TY19zHVftm5N4JgvbAgs=";
        postInstall =
          builtins.replaceStrings
            [ "resources/onedriver.desktop" ]
            [ "resources/onedriver-launcher.desktop" ]
            oldAttrs.postInstall;
      });
    })
  ];

  environment.systemPackages = with pkgs; [
    bat
    binutils
    btop
    eza
    file
    fzf
    git
    jq
    nixfmt-rfc-style
    nixpkgs-fmt
    python3
    wget
    zoxide
    podman-compose
    dnsutils
    brave
    vscode
    drm_info
    _7zz
    obsidian
  ];

  hardware.graphics.enable = true;

  fonts.fontconfig = {
    defaultFonts.monospace = [ "Hack Nerd Font Mono" ];
    antialias = true;
    hinting.enable = true;
    hinting.style = "full";
    subpixel.rgba = "none";
  };
  fonts.packages = with pkgs; [ nerd-fonts.hack ];

  programs = {
    zsh.enable = true;
    fzf.fuzzyCompletion = true;
    neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      withPython3 = true;
    };
  };

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;
  };
  virtualisation.docker.enable = lib.mkForce false;

  users.defaultUserShell = pkgs.zsh;
  users.users =
    let
      mkUser = {
        isNormalUser = true;
        extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
      };
    in {
      admin = mkUser;
      caleb = mkUser;
    };

  system.stateVersion = "25.11";
}
