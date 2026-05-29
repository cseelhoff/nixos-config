{ config, lib, pkgs, nixos-vscode-server, code-insiders, ... }:

# VS Code Remote Tunnels support.
#
# Three layers:
#   - nix-ld: lets the host-side `code-insiders tunnel` CLI (a prebuilt
#     Microsoft binary linked against FHS glibc/libstdc++) actually run.
#   - nixos-vscode-server: autoPatchelfHooks the per-connection server
#     payload Microsoft drops into ~/.vscode-server-insiders/ when a
#     client connects.
#   - A declarative systemd --user unit for `code-insiders tunnel`, with
#     file-based token storage so it comes back unattended after reboot
#     (no keyring unlock required, no login session required).

let
  vscodeInsiders =
    code-insiders.packages.${pkgs.stdenv.hostPlatform.system}.vscode-insider;
in
{
  imports = [ nixos-vscode-server.nixosModules.default ];

  # Start the user-level tunnel service at boot without requiring a
  # login session. Without linger, the unit only fires after caleb's
  # first interactive login of the boot — defeating headless tunneling.
  users.users.caleb.linger = true;

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

  services.vscode-server = {
    enable = true;
    # The tunnel CLI drops Insiders server payloads under
    # ~/.vscode-insiders/cli/servers/, NOT ~/.vscode-server/. Without
    # this second path, autoPatchelf never touches them and connecting
    # via vscode.dev fails with:
    #   "failed to run command code-server-insiders --version
    #    code 127 env: 'sh': No such file or directory"
    # (the prebuilt ELF's interpreter /lib64/ld-linux-x86-64.so.2
    # doesn't exist on NixOS). The autofix script splits this on ':'.
    installPath = "$HOME/.vscode-server:$HOME/.vscode-insiders";
  };

  # Declarative replacement for the unit that
  # `code-insiders tunnel service install` writes to
  # ~/.config/systemd/user/. That imperative unit (a) pins a /nix/store
  # path that goes stale on every rebuild, and (b) doesn't set
  # VSCODE_CLI_USE_FILE_KEYCHAIN, so the CLI tries libsecret at startup,
  # finds no unlocked gnome-keyring (KDE here uses kwallet, and there's
  # no interactive unlock at boot anyway), and falls back to an
  # interactive device-code login forever.
  #
  # One-time bootstrap after `nixos-rebuild switch`:
  #   rm -f ~/.config/systemd/user/code-insiders-tunnel.service
  #   systemctl --user daemon-reload
  #   VSCODE_CLI_USE_FILE_KEYCHAIN=1 code-insiders \
  #     --cli-data-dir ~/.vscode-insiders/cli \
  #     tunnel user login --provider github
  #   systemctl --user enable --now code-insiders-tunnel.service
  # After that, reboots bring the tunnel back with no interaction.
  systemd.user.services.code-insiders-tunnel = {
    description = "Visual Studio Code - Insiders Tunnel (declarative)";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "default.target" ];

    # NixOS user units start with an empty PATH unless told otherwise.
    # The tunnel spawns the per-connection server payload whose entry
    # script begins with `#!/usr/bin/env sh` — `env` does a PATH lookup
    # for `sh`, so without PATH the spawn dies with:
    #   "failed to run command code-server-insiders --version
    #    (code 127): env: 'sh': No such file or directory"
    # Adding `bash` (and friends) to the unit's PATH satisfies the
    # shebang and gives the server the usual tooling.
    path = with pkgs; [
      bash
      coreutils       # `env` lives here (and is what the server scripts call)
      gnused
      gnugrep
      gawk
      gnutar
      gzip
      git             # vscode server frequently shells out to git
      # The integrated terminals VS Code spawns are children of this
      # service and inherit its PATH. Without the system and per-user
      # profile dirs, those terminals (which aren't login shells and so
      # never re-source /etc/profile) can't see system packages like
      # `odin`/`clang` or home-manager programs like `zoxide`/`eza`.
      "/run/current-system/sw"
      "/etc/profiles/per-user/caleb"
    ];

    environment = {
      # Store the OAuth refresh token as a plaintext file inside
      # --cli-data-dir instead of the OS keyring. Required for headless
      # / pre-login startup; without this the CLI hangs forever in
      # "authorization_pending" after every boot.
      VSCODE_CLI_USE_FILE_KEYCHAIN = "1";
    };

    serviceConfig = {
      Type = "simple";
      Restart = "always";
      RestartSec = 10;
      # The tunnel CLI lives under lib/vscode/bin, not bin/, in this flake.
      # $out/bin/ only exposes `code-insiders` itself.
      ExecStart = ''
        ${vscodeInsiders}/lib/vscode/bin/code-tunnel-insiders \
          --verbose \
          --cli-data-dir %h/.vscode-insiders/cli \
          tunnel service internal-run
      '';
    };
  };
}
