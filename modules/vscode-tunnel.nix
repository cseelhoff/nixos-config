{ config, lib, pkgs, nixos-vscode-server, ... }:

# VS Code Remote Tunnels support.
#
# Two layers, both needed because they patch different binaries:
#   - nix-ld: lets the host-side `code-insiders tunnel` CLI (a prebuilt
#     Microsoft binary linked against FHS glibc/libstdc++) actually run.
#   - nixos-vscode-server: autoPatchelfHooks the per-connection server
#     payload Microsoft drops into ~/.vscode-server-insiders/ when a
#     client connects.

{
  imports = [ nixos-vscode-server.nixosModules.default ];

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc   # libstdc++
      zlib
      openssl
      curl
      icu
      libsecret      # keytar / credential storage
      libkrb5
      nss
      nspr
      libgcc
    ];
  };

  services.vscode-server.enable = true;
}
