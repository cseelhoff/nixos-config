{
  description = "NixOS config — x870 (GNOME + Hyprland + Gaming) + WSL";

  inputs = {
    # Stable base — most packages come from here so we get Hydra cache hits.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    # Unstable cherry-pick — used per-package via specialArgs.nixpkgs-unstable
    # for things we want bleeding-edge (e.g. onedriver auth fixes).
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    # Ollama-only nixpkgs pin (consumed solely by modules/ollama.nix). Stable
    # (nixos-25.11) ships Ollama 0.21.1, whose bundled llama.cpp doesn't know the
    # `gemma4` architecture — an imported gemma4 GGUF carrying a vision projector
    # fails to load ("unknown model architecture: 'gemma4'"). Tracking unstable
    # here gives a >=0.30 Ollama with a gemma4-aware llama.cpp. Kept SEPARATE from
    # nixpkgs-unstable on purpose: bumping Ollama must not churn the code-insiders
    # / odin / onedriver closures that follow that shared input.
    nixpkgs-ollama.url = "github:nixos/nixpkgs/nixos-unstable";
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
      url = "github:iosmanthus/code-insiders-flake/618521df86f02492e8dc15966e0400ffdd2bcece";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    nixos-vscode-server = {
      # Per-connection autoPatchelf of the VS Code server payload that
      # gets dropped into ~/.vscode-server[-insiders]/ on each connect.
      url = "github:nix-community/nixos-vscode-server";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    foundryvtt = {
      # Community FoundryVTT server packaging + NixOS module
      # (services.foundryvtt). The proprietary server zip is NOT fetched
      # by Nix — it must be added to the store by hand from your licensed
      # foundryvtt.com download; see modules/foundryvtt.nix for the steps.
      # Follows our stable nixpkgs so the node/runtime closure is shared.
      #
      # Points at a LOCAL clone (not github:nix-foundryvtt/nix-foundryvtt)
      # because upstream only packages up to build 14.361, but the Foundry
      # site serves 14.364. The clone carries a locally-generated 14.364
      # entry (via the repo's own updateScript). To re-sync with upstream
      # once it ships a newer build: cd ~/src/nix-foundryvtt && git pull,
      # then `nix flake lock --update-input foundryvtt` here.
      url = "git+file:///home/caleb/src/nix-foundryvtt";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, nixpkgs-ollama, home-manager, nixos-wsl, partydeck, code-insiders, nixos-vscode-server, foundryvtt, ... }:
    let
      mkNixos = hostName: hostModule: nixpkgs.lib.nixosSystem {
        modules = [
          ./modules/base.nix
          hostModule
          { networking.hostName = hostName; }
        ];
        specialArgs = {
          inherit self home-manager nixos-wsl partydeck code-insiders nixpkgs-unstable nixpkgs-ollama nixos-vscode-server foundryvtt;
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
