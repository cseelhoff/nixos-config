{ config, pkgs, nixos-wsl, ... }:
{
  imports = [
    ../hardware/wsl-hardware-configuration.nix
    nixos-wsl.nixosModules.default
  ];

  # WSL uses the Windows NVIDIA driver (no kernel module on the Linux side).
  # We intentionally do NOT set nixpkgs.config.cudaSupport = true here:
  # it forces a from-source rebuild of every CUDA-linked package because
  # Hydra only caches the non-CUDA variants. The userspace cudatoolkit
  # below is cached and is what apps actually consume in WSL.

  wsl = {
    enable = true;
    defaultUser = "caleb";
    useWindowsDriver = true;
    startMenuLaunchers = true;
    wslConf.network.hostname = "wsl";
    extraBin = [
      { src = "${pkgs.coreutils}/bin/mkdir"; }
      { src = "${pkgs.coreutils}/bin/cat"; }
      { src = "${pkgs.coreutils}/bin/whoami"; }
      { src = "${pkgs.coreutils}/bin/ls"; }
      { src = "${pkgs.coreutils}/bin/mv"; }
      { src = "${pkgs.coreutils}/bin/id"; }
      { src = "${pkgs.coreutils}/bin/uname"; }
      { src = "${pkgs.busybox}/bin/addgroup"; }
      { src = "${pkgs.shadow}/bin/groupadd"; }
      { src = "${pkgs.shadow}/bin/usermod"; }
      { src = "${pkgs.podman}/bin/podman"; }
    ];
  };

  environment = {
    sessionVariables = {
      CUDA_PATH = "${pkgs.cudatoolkit}";
      LD_LIBRARY_PATH = "/usr/lib/wsl/lib";
    };
    systemPackages = [ pkgs.cudatoolkit ];
  };

  programs.nix-ld = {
    enable = true;
    package = pkgs.nix-ld;
  };
}

