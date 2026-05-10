{
  description = "NixOS config — x870 (GNOME + Hyprland + Gaming) + WSL";

  inputs = {
    # Stable base — most packages come from here so we get Hydra cache hits.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    # Unstable cherry-pick — used per-package via specialArgs.nixpkgs-unstable
    # for things we want bleeding-edge (e.g. onedriver auth fixes).
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      # Pin to the home-manager release matching our stable nixpkgs.
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    partydeck = {
      url = "github:cseelhoff/partydeck";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    code-insiders = {
      # VS Code Insiders, auto-updated daily via upstream GitHub Action.
      # Follows unstable so it gets the freshest glibc/electron deps.
      # Launch:  `code-insiders`  (installed in home/caleb.nix)
      # Update:  `nix flake update code-insiders && sudo nixos-rebuild switch --flake .#<host>`
      url = "github:iosmanthus/code-insiders-flake";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, nixos-wsl, partydeck, code-insiders, ... }:
    let
      mkNixos = hostName: hostModule: nixpkgs.lib.nixosSystem {
        modules = [
          ./modules/base.nix
          hostModule
          { networking.hostName = hostName; }
        ];
        specialArgs = {
          inherit self home-manager nixos-wsl partydeck code-insiders nixpkgs-unstable;
        };
      };
      forAllSystems = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ];
    in {
      nixosConfigurations = {
        nixos-gui = mkNixos "nixos-gui" ./hosts/nixos-gui.nix;
        x870 = mkNixos "x870" ./hosts/x870.nix;
        wsl = mkNixos "wsl" ./hosts/wsl.nix;
      };

      devShells = forAllSystems (system:
        let pkgs = import nixpkgs { inherit system; };
        in {
          default = pkgs.mkShell {
            packages = with pkgs; [
              nix
              nixpkgs-fmt
              nil
              git
            ];
          };
        });
    };
}
