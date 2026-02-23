{ pkgs, lib, home-manager, omarchy-nix, ... }:
{
  imports = [
    home-manager.nixosModules.home-manager
    omarchy-nix.nixosModules.default
    ../home/admin.nix
    ../home/caleb.nix
  ];

  home-manager.backupFileExtension = "backup";

  omarchy = {
    full_name = "Admin User";
    email_address = "admin@example.com";
    theme = "tokyo-night";
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.cudaSupport = true;

  environment.systemPackages = with pkgs; [
    bat
    btop
    eza
    fzf
    git
    nixfmt-rfc-style
    nixpkgs-fmt
    wget
    zoxide
    podman-compose
    dnsutils
    brave
    nvtopPackages.full
    vscode
    cudatoolkit
    cudaPackages.cudnn
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
  users.users = {
    admin = {
      isNormalUser = true;
      extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
    };
    caleb = {
      isNormalUser = true;
      extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
    };
  };

  system.stateVersion = "25.11";
}