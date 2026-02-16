{
  description = "NixOS config with Omarchy (desktop) + WSL variant";

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
      system = "x86_64-linux";

      # Shared base for both desktop and WSL
      baseModule = { pkgs, ... }: {
        imports = [
          home-manager.nixosModules.home-manager
          omarchy-nix.nixosModules.default
        ];

        # Unified Omarchy config — applies to both hosts
        omarchy = {
          full_name     = "Admin User";
          email_address = "admin@example.com";
          theme         = "tokyo-night";
          # Optional: add if you want wallpaper-based theming later
          # theme_overrides = { wallpaper_path = ./wallpapers/default.png; };
        };

        nix.settings.experimental-features = [ "nix-command" "flakes" ];
        nixpkgs.config.allowUnfree = true;

        environment.systemPackages = with pkgs; [
          bat
          btop
          eza
          fzf
          git
          nixpkgs-fmt
          wget
          zoxide
        ];

        programs.zsh = {
          enable = true;
          autosuggestions.enable = true;
          syntaxHighlighting.enable = true;
          ohMyZsh = {
            enable = true;
            theme = "risto";
            plugins = [ "git" "history" "zoxide" ];
          };
        };

        users.defaultUserShell = pkgs.zsh;

        users.users.admin = {
          isNormalUser = true;
          extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
        };

        # Home-Manager shared config
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          users.admin = {
            imports = [
              omarchy-nix.homeManagerModules.default
            ];

            programs = {
              bat.enable = true;
              eza = {
                enable = true;
                enableZshIntegration = true;
                icons = true;
                git = true;
              };
              fzf.enable = true;
              zoxide = {
                enable = true;
                options = [ "--cmd" "cd" ];
              };
              zsh = {
                enable = true;
                autosuggestion.enable = true;
                syntaxHighlighting.enable = true;
                oh-my-zsh = {
                  enable = true;
                  theme = "risto";
                  plugins = [ "git" "history" "zoxide" ];
                };
              };
            };

            home.stateVersion = "25.11";
          };
        };

        system.stateVersion = "25.11";
      };

      # Helper to build a system with base + extras
      mkNixos = hostname: extraModules: nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          baseModule
          {
            networking.hostName = hostname;
          }
        ] ++ extraModules;
      };

    in {
      nixosConfigurations = {

        desktop = mkNixos "desktop" [
          ./hardware-configuration.nix
        ];

        wsl = mkNixos "wsl" [
          nixos-wsl.nixosModules.default

          {
            wsl = {
              enable = true;
              useWindowsDriver = true;
              startMenuLaunchers = true;
              extraBin = with nixpkgs.legacyPackages.${system}; [
                { src = "${coreutils}/bin/mkdir"; }
                { src = "${coreutils}/bin/cat"; }
                { src = "${coreutils}/bin/whoami"; }
                { src = "${coreutils}/bin/ls"; }
                { src = "${coreutils}/bin/mv"; }
                { src = "${coreutils}/bin/id"; }
                { src = "${coreutils}/bin/uname"; }
                { src = "${busybox}/bin/addgroup"; }
                { src = "${su}/bin/groupadd"; }
                { src = "${su}/bin/usermod"; }
                { src = "${podman}/bin/podman"; }
              ];
            };

            environment = {
              sessionVariables = {
                CUDA_PATH = "${nixpkgs.legacyPackages.${system}.cudatoolkit}";
                LD_LIBRARY_PATH = "/usr/lib/wsl/lib";
              };
              systemPackages = with nixpkgs.legacyPackages.${system}; [
                cudatoolkit
                podman-compose
              ];
            };

            programs = {
              fzf.fuzzyCompletion = true;
              neovim = {
                enable = true;
                defaultEditor = true;
                viAlias = true;
                withPython3 = true;
              };
              nix-ld = {
                enable = true;
                package = nixpkgs.legacyPackages.${system}.nix-ld-rs;
              };
            };

            services.onedrive.enable = true;

            virtualisation.podman = {
              enable = true;
              dockerCompat = true;
              defaultNetwork.settings.dns_enabled = true;
            };
          }
        ];
      };
    };
}
