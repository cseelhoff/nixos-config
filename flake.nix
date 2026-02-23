{
  description = "NixOS config with Omarchy (desktop) + WSL + x870 (refactored)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    omarchy-nix = {
      url = "github:henrysipp/omarchy-nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, omarchy-nix, nixos-wsl, ... }:
    let
      mkNixos = hostName: hostModule: nixpkgs.lib.nixosSystem {
        modules = [
          ./modules/base.nix
          hostModule
          { networking.hostName = hostName; }
        ];
        specialArgs = { inherit home-manager omarchy-nix nixos-wsl; };
      };
    in {
      nixosConfigurations = {
        desktop = mkNixos "desktop" ./hosts/desktop.nix;
        x870 = mkNixos "x870" ./hosts/x870.nix;
        wsl = mkNixos "wsl" ./hosts/wsl.nix;
      };
    };
}