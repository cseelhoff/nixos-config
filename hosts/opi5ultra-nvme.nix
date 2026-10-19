{ opi5ultra, ... }:

# The same Orange Pi 5 Ultra system installed on the board's NVMe instead of
# the SD card (root filesystem and boot from orangepi5ultra-nixos's nvme-root
# module; see that file for how the disk is prepared).
#
#   cd ~/nixos-config && sudo nixos-rebuild switch --flake '.#opi5ultra-nvme'
#
# The SPI U-Boot prefers the SD card: remove it to boot the NVMe.

{
  imports = [
    opi5ultra.nixosModules.nvme
    ./opi5ultra-common.nix
  ];
}
