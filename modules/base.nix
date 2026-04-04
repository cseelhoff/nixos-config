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
  nixpkgs.config.cudaSupport = true;

  environment.systemPackages = with pkgs; [
    bat
    binutils
    btop
    eza
    file
    fzf
    git
    nixfmt-rfc-style
    nixpkgs-fmt
    python3
    wget
    zoxide
    podman-compose
    dnsutils
    brave
    nvtopPackages.full
    vscode
    cudatoolkit
    cudaPackages.cudnn
    drm_info
    _7zz
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
