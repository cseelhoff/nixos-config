{
  lib,
  appimageTools,
  fetchurl,
}:

# Note on updates:
# DLSS 5 Swapper's in-app self-updater cannot replace an immutable package in
# /nix/store (note: RenoDX add-on updates and first-run payload downloads write
# to ~/.config/dlss5-swapper/ and still work normally).
# To update the application itself, bump `version` and `sha256` below from the
# latest release's SHA256SUMS.txt — or run `./scripts/update-dlss5-swapper.sh`
# from the repo root — then rebuild NixOS.
let
  pname = "dlss5-swapper";
  version = "2.2.9-linux.5";

  src = fetchurl {
    url = "https://github.com/Nicholasvoador/DLSS5-Swapper-Linux-Support/releases/download/v${version}/DLSS5-Swapper-Linux-${version}-x86_64.AppImage";
    # Pinned directly from upstream release SHA256SUMS.txt
    sha256 = "3f5e210e33e36ddec119bdaf71550c89a942474a1f13b2aa311513f822be00ea";
  };

  appimageContents = appimageTools.extract {
    inherit pname version src;
  };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraPkgs =
    pkgs: with pkgs; [
      # Electron / Chromium runtime libraries
      alsa-lib
      at-spi2-atk
      at-spi2-core
      gtk3
      libdrm
      libgbm
      libnotify
      libsecret
      libxkbcommon
      libxscrnsaver
      libxshmfence
      libxtst
      mesa
      nspr
      nss
      util-linux # unshare (used by AppRun sandbox check), libuuid, setsid
      wayland
      xdg-utils

      # Runtime helpers invoked by Swapper for payload extraction, DLSS5VKLayer
      # archive extraction, and running ReShade setup under GE-Proton
      _7zz
      gnutar
      gzip
      python3
    ];

  extraInstallCommands = ''
    install -Dm444 ${appimageContents}/dlss5-swapper.desktop \
      $out/share/applications/dlss5-swapper.desktop
    substituteInPlace $out/share/applications/dlss5-swapper.desktop \
      --replace-fail 'Exec=AppRun --no-sandbox %U' "Exec=$out/bin/${pname} %U"

    # Upstream ships a 1278x1278 PNG, which is not a standard hicolor bucket in
    # index.theme; install into 512x512/apps and pixmaps so launchers find it.
    install -Dm444 \
      ${appimageContents}/usr/share/icons/hicolor/1278x1278/apps/dlss5-swapper.png \
      $out/share/icons/hicolor/512x512/apps/dlss5-swapper.png
    install -Dm444 \
      ${appimageContents}/usr/share/icons/hicolor/1278x1278/apps/dlss5-swapper.png \
      $out/share/pixmaps/dlss5-swapper.png
  '';

  meta = {
    description = "DLSS 5 (Neural Rendering) manager for Linux Steam/Proton and Vulkan games";
    homepage = "https://github.com/Nicholasvoador/DLSS5-Swapper-Linux-Support";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = pname;
  };
}
