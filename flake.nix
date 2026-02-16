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
      # No top-level 'system' definition needed anymore

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
          podman-compose
        ];

        programs = {
          zsh = {
            enable = true;
            autosuggestions.enable = true;
            syntaxHighlighting.enable = true;
            ohMyZsh = {
              enable = true;
              theme = "risto";
              plugins = [ "git" "history" "zoxide" ];
            };
          };

          fzf.fuzzyCompletion = true;

          neovim = {
            enable = true;
            defaultEditor = true;
            viAlias = true;
            withPython3 = true;
          };
        };

        virtualisation.podman = {
          enable = true;
          dockerCompat = true;
          defaultNetwork.settings.dns_enabled = true;
        };

        services.onedrive.enable = true;

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
          {
            boot.loader = {
              systemd-boot.enable = false;

              # Use GRUB for compatibility with both UEFI and legacy BIOS
              grub = {
                enable = true;
                version = 2;
                device = "nodev";               # UEFI: no legacy MBR write
                efiSupport = true;              # Enables EFI/UEFI mode
                # efiInstallAsRemovable = true; # Only if you set canTouchEfiVariables = false
                useOSProber = true;
                configurationLimit = 10;
              };

              efi = {
                canTouchEfiVariables = true;
                efiSysMountPoint = "/boot";
              };
            };
          }
        ];

        wsl = mkNixos "wsl" [
          nixos-wsl.nixosModules.default
          ({ pkgs, ... }: {
            wsl = {
              enable = true;
              useWindowsDriver = true;
              startMenuLaunchers = true;
              extraBin = with nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system}; [
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
                CUDA_PATH = "${nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system}.cudatoolkit}";
                LD_LIBRARY_PATH = "/usr/lib/wsl/lib";
              };
              systemPackages = with nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system}; [
                cudatoolkit
              ];
            };
        
            programs.nix-ld = {
              enable = true;
              package = nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system}.nix-ld-rs;
            };
          })
        ];
      };
    };
}
