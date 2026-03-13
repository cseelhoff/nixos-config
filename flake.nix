{
  description = "NixOS config — x870 (GNOME + Hyprland + Gaming) + WSL";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, nixos-wsl, ... }:
    let
      mkNixos = hostName: hostModule: nixpkgs.lib.nixosSystem {
        modules = [
          ./modules/base.nix
          hostModule
          { networking.hostName = hostName; }
        ];
        specialArgs = {
          inherit self home-manager nixos-wsl;
        };
      };
    in {
      nixosConfigurations = {
        desktop = mkNixos "desktop" ./hosts/desktop.nix;
        x870 = mkNixos "x870" ./hosts/x870.nix;
        wsl = mkNixos "wsl" ./hosts/wsl.nix;
      };
    };
}
