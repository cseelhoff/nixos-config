# Minimal "hardware" config for the WSL host.
#
# NixOS-WSL (nixos-wsl.nixosModules.default, imported in hosts/wsl.nix)
# provides the root filesystem and boot setup, so the only thing this file
# must supply for a flake build is the host platform. Without it, eval fails
# with `nixpkgs.hostPlatform not set` (see README bootstrap notes), because
# mkNixos in flake.nix does not pass a `system` and NixOS-WSL does not set
# hostPlatform itself. Kept as a per-host file to match the other hosts.
{ lib, ... }:
{
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
