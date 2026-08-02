{ config, pkgs, nixos-wsl, ... }:
{
  imports = [
    ../hardware/wsl-hardware-configuration.nix
    nixos-wsl.nixosModules.default
  ];

  # No CUDA here on purpose. `nixpkgs.config.cudaSupport` would force a
  # from-source rebuild of every CUDA-linked package (Hydra only caches the
  # non-CUDA variants), and even the plain `cudatoolkit` package is a multi-GB
  # closure. WSL exposes the Windows NVIDIA driver at /usr/lib/wsl/lib, so GPU
  # work is better done per-project (devShell / container / uv venv wheels)
  # than baked into the system closure.

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

  # Windows NVIDIA driver stubs (libcuda.so, nvidia-smi) live here.
  environment.sessionVariables.LD_LIBRARY_PATH = "/usr/lib/wsl/lib";

  programs.nix-ld = {
    enable = true;
    package = pkgs.nix-ld;
  };
}

