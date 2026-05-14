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

  # Allow unfree for ad-hoc `nix run --impure nixpkgs#...` invocations.
  # System nixpkgs.config above only affects the NixOS build, not the user's
  # flake-based nix CLI evaluations, which read this env var when --impure.
  environment.variables.NIXPKGS_ALLOW_UNFREE = "1";

  # Disable openldap's flaky test017-syncreplication-refresh, which is
  # timing-dependent (hardcoded `sleep 7` waits for replication) and fails
  # intermittently on fast/loaded machines. Pulled in transitively via
  # cyrus-sasl → dbus → accounts-daemon, so failures block any rebuild.
  nixpkgs.overlays = [
    (final: prev: {
      openldap = prev.openldap.overrideAttrs (_: { doCheck = false; });
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
    nixfmt
    nixpkgs-fmt
    python3
    wget
    zoxide
    podman-compose
    dnsutils
    drm_info
    _7zz
    odin
    clang
    llvmPackages.llvm
    llvmPackages.bintools
    lldb
  ];

  programs = {
    zsh.enable = true;
    fzf.fuzzyCompletion = true;
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
