{ config, pkgs, lib, opi5ultra, ... }:

# Orange Pi 5 Ultra (RK3588, aarch64), booted from the image built by
# github:cseelhoff/orangepi5ultra-nixos. That flake's module provides the
# kernel, device tree, firmware, filesystems and extlinux bootloader, so there
# is no hardware/*-hardware-configuration.nix for this host.
#
# First switch after flashing:
#   git clone https://github.com/cseelhoff/nixos-config.git ~/nixos-config
#   cd ~/nixos-config && sudo nixos-rebuild switch --flake '.#opi5ultra'

{
  imports = [
    opi5ultra.nixosModules.default
  ];

  # The image was first installed as 26.05; base.nix pins 25.11 for older hosts.
  system.stateVersion = lib.mkForce "26.05";

  networking.networkmanager.enable = true;
  time.timeZone = "America/Chicago";

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
    };
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      KbdInteractiveAuthentication = true;
      PermitRootLogin = "no";
    };
  };

  users.users.caleb = {
    extraGroups = [ "render" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDexbF/Hyk975Dn0M5Y9455dXEMzkEtp3ksXVeGAhEbF"
    ];
  };

  # Hardware / performance testing.
  environment.systemPackages = with pkgs; [
    vulkan-tools
    mesa-demos
    glmark2
    vkmark
    v4l-utils
    ffmpeg
    fio
    iperf3
    stress-ng
    htop
    pciutils
    usbutils
  ];
}
