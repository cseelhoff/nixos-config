{ opi5ultra, ... }:

# Orange Pi 5 Ultra (RK3588, aarch64) booted from the SD card image built by
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
    ./opi5ultra-common.nix
  ];
}
