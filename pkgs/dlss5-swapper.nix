{
  lib,
  appimageTools,
  asar,
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

    # Upstream v2.2.9-linux.5 joins uppercase 'System32'/'SysWOW64' and mixed-case
    # DLL names against Proton's lowercase `<prefix>/drive_c/windows/system32` on
    # case-sensitive Linux filesystems, causing false-positive "Install or repair
    # the official Microsoft Visual C++ runtime" failures on Proton prefixes.
    postExtract = ''
      ${lib.getExe asar} extract $out/resources/app.asar "$TMPDIR/app"
      chmod -R u+w "$TMPDIR/app" "$out/resources"

      substituteInPlace "$TMPDIR/app/src/core/runtime-components.js" \
        --replace-fail \
          "function missingVCRuntime(bitness, exeDir, systemRoot = process.env.SystemRoot, extra = []) {
  if (!systemRoot) return [];
  const systemDir = path.join(systemRoot, bitness === 32 ? 'SysWOW64' : 'System32');
  const names = ['msvcp140.dll', 'vcruntime140.dll', ...(bitness === 64 ? ['vcruntime140_1.dll'] : []), ...extra];
  return names.filter(name => {
    const local = exeDir && path.join(exeDir, name);
    const file = local && fs.existsSync(local) ? local : path.join(systemDir, name);
    return pe.getBitness(file) !== bitness;
  });
}" \
          "function resolveCaseInsensitive(dir, name) {
  if (!dir) return null;
  const direct = path.join(dir, name);
  if (fs.existsSync(direct)) return direct;
  try {
    const lower = name.toLowerCase();
    const match = fs.readdirSync(dir).find(entry => entry.toLowerCase() === lower);
    return match ? path.join(dir, match) : direct;
  } catch { return direct; }
}

function missingVCRuntime(bitness, exeDir, systemRoot = process.env.SystemRoot, extra = []) {
  if (!systemRoot) return [];
  const systemDir = resolveCaseInsensitive(systemRoot, bitness === 32 ? 'SysWOW64' : 'System32');
  const names = ['msvcp140.dll', 'vcruntime140.dll', ...(bitness === 64 ? ['vcruntime140_1.dll'] : []), ...extra];
  return names.filter(name => {
    const local = exeDir && resolveCaseInsensitive(exeDir, name);
    const file = local && fs.existsSync(local) ? local : resolveCaseInsensitive(systemDir, name);
    return pe.getBitness(file) !== bitness;
  });
}"

      substituteInPlace "$TMPDIR/app/src/core/compatibility.js" \
        --replace-fail \
          "  const file = path.join(exeDir, 'D3DCompiler_47.dll');" \
          "  let match = 'D3DCompiler_47.dll';
  try { match = fs.readdirSync(exeDir).find(item => item.toLowerCase() === 'd3dcompiler_47.dll') || match; } catch {}
  const file = path.join(exeDir, match);"

      substituteInPlace "$TMPDIR/app/src/core/apply.js" \
        --replace-fail \
          "  const system = path.join(systemRoot, 'System32', 'D3DCompiler_47.dll');" \
          "  const sysDirName = (() => { try { return fs.readdirSync(systemRoot).find(e => e.toLowerCase() === 'system32') || 'System32'; } catch { return 'System32'; } })();
  const sysDir = path.join(systemRoot, sysDirName);
  const sysDllName = (() => { try { return fs.readdirSync(sysDir).find(e => e.toLowerCase() === 'd3dcompiler_47.dll') || 'D3DCompiler_47.dll'; } catch { return 'D3DCompiler_47.dll'; } })();
  const system = path.join(sysDir, sysDllName);"

      rm -rf "$out/resources/app.asar" "$out/resources/app.asar.unpacked"
      ${lib.getExe asar} pack --unpack-dir "node_modules/7zip-bin" "$TMPDIR/app" "$out/resources/app.asar"
    '';
  };
in
appimageTools.wrapAppImage {
  inherit pname version;
  src = appimageContents;

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
