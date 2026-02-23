{ config, pkgs, nixos-wsl, ... }:
{
  imports = [ nixos-wsl.nixosModules.default ];

  wsl = {
    enable = true;
    useWindowsDriver = true;
    startMenuLaunchers = true;
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
    package = pkgs.nix-ld-rs;
  };
}

