{ config, lib, pkgs, foundryvtt, ... }:

# Foundry Virtual Tabletop server — community `nix-foundryvtt` packaging.
#
# Runs Foundry as a hardened systemd system service (dedicated `foundryvtt`
# user, data under /var/lib/foundryvtt) listening on TCP 30000 for direct
# LAN play. No reverse proxy / TLS here yet; to expose it to the internet
# later, add nginx + security.acme and flip proxySSL/proxyPort below.
#
# IMPORTANT — the proprietary server zip is NOT fetched by Nix. Foundry
# requires a login to download, so the package is a `requireFile`
# derivation: the zip must already be in the store (by name + sha256)
# for the build to succeed. Currently pinned: build 14.364, already
# added with a GC root at ~/.nix-foundry-roots/ so nix-collect-garbage
# can't drop it.
#
# The `foundryvtt` flake input points at a LOCAL clone
# (~/src/nix-foundryvtt), not upstream github, because upstream only
# packages up to 14.361 while the Foundry site serves 14.364. The clone
# carries a locally-generated 14.364 entry produced by the repo's own
# updateScript. See the input comment in flake.nix.
#
# UPGRADING to a newer Foundry build later:
#   1. Download the new *Linux/NodeJS* build (NOT the Windows/macOS app)
#      from https://foundryvtt.com → Account → Purchased Licenses. The
#      file is named FoundryVTT-Linux-14.<build>.zip.
#   2. If upstream nix-foundryvtt already lists that build, just point
#      the flake input back at github and `nix flake update foundryvtt`.
#      Otherwise regenerate it in the clone:
#        cd ~/src/nix-foundryvtt
#        nix build .#foundryvtt.passthru.updateScript
#        ./result ~/Downloads/FoundryVTT-Linux-14.<build>.zip stable
#        git commit -am "foundryvtt_14: add 14.0.0+<build>"
#        cd ~/nixos-config && nix flake lock --update-input foundryvtt
#   3. Add the zip to the store and pin a GC root:
#        storepath=$(nix-store --add-fixed sha256 \
#          ~/Downloads/FoundryVTT-Linux-14.<build>.zip)
#        nix-store --add-root \
#          ~/.nix-foundry-roots/FoundryVTT-Linux-14.<build>.zip -r "$storepath"
#   4. Rebuild:  sudo nixos-rebuild switch --flake ~/nixos-config#x870
#
#   Verify before rebuilding — this catches a bad hash without needing sudo:
#     nix build --no-link --print-out-paths \
#       '.#nixosConfigurations.x870.config.services.foundryvtt.package'
#
#   NOTE the zip flavour: use the *Linux* build (~250 MB, Electron layout with
#   resources/app/main.js), which is what these steps and every existing GC root
#   use. The separate FoundryVTT-Node-<build>.zip (~148 MB, main.js at the root)
#   is the headless server archive and is NOT what this packaging expects.
#
# Activate your license key and create worlds via the web UI on first run.

{
  imports = [ foundryvtt.nixosModules.foundryvtt ];

  services.foundryvtt = {
    enable = true;

    # Pin the v14 line; the input tracks its latest stable build.
    package = foundryvtt.packages.${pkgs.stdenv.hostPlatform.system}.foundryvtt_14;

    # hostName defaults to networking.hostName ("x870") and only affects
    # the address shown in invitation links — Foundry still binds all
    # interfaces on `port`. Players join at http://x870:30000 (or the
    # host's LAN IP). Set this to a real DNS name if you add one.

    minifyStaticFiles = true;  # serve minified JS/CSS — less bandwidth
    upnp = false;              # don't let Foundry punch a router hole; LAN-only
  };

  # The module hardens the service but deliberately leaves the firewall
  # alone. Direct LAN access needs the listen port opened explicitly.
  networking.firewall.allowedTCPPorts = [ config.services.foundryvtt.port ];

  # Read-only visibility into the service's data directory for the admin user.
  #
  # /var/lib/foundryvtt is drwxr-x--- foundryvtt:foundryvtt, so nothing outside
  # the service can see which packages are installed or what the world config
  # says. foundry-autoconfig's read-only `status` and `plan` commands need that
  # visibility to diff the install against a declared profile.
  #
  # Group membership rather than sudo is deliberate: the group already has r-x
  # and no write bit, so this grants exactly read and traverse and cannot be
  # escalated into a write. The tool never writes here by design — it emits a
  # runbook for a human instead (foundry-autoconfig ADR 0008).
  #
  # NixOS merges extraGroups across modules, so this composes with the entries
  # in base.nix and gaming.nix rather than replacing them.
  users.users.caleb.extraGroups = [ "foundryvtt" ];
}
