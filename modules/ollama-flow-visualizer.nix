{ lib, pkgs, ... }:

# Ollama Flow Visualizer (github.com/Paxy/Ollama-flow-visualizer) — a transparent
# proxy that sits in front of modules/ollama.nix and streams every request and
# response to a live web dashboard (grouped by prompt, with tool calls, thinking
# tokens, and per-request durations). Only useful on a host that also imports
# modules/ollama.nix.
#
#   client → proxy 127.0.0.1:11437 → ollama 127.0.0.1:11434
#                  ↓
#            dashboard http://127.0.0.1:11438
#
# Nothing is monitored until a client is pointed at the PROXY port instead of
# 11434. modules/open-webui.nix is wired that way; dnd-ai and the `ollama` CLI
# still talk to 11434 directly, so re-point them (OLLAMA_HOST=127.0.0.1:11437)
# when you want their traffic on the dashboard.
#
# Ports are NOT upstream's defaults (proxy 11435, dashboard 8080): 11435 is
# grok-bridge and 8080 is mitmproxy's default, which ad-hoc `mitmdump` captures
# on this box take. 11437/11438 continue the local LLM block — 11434 ollama,
# 11435 grok-bridge, 11436 open-webui.
#
# History is in-memory only (a 500-entry ring buffer, cleared on restart), so the
# unit needs no state directory — hence ProtectSystem=strict with no exceptions.
#
# Upstream is pinned by revision: it publishes no releases, and `config.json` is
# read from the script's own directory, so the settings below are baked into the
# store path rather than passed at runtime.

let
  proxyPort = 11437;
  dashboardPort = 11438;
  ollamaPort = 11434; # services.ollama default, see modules/ollama.nix

  configFile = pkgs.writeText "ollama-flow-visualizer-config.json" (builtins.toJSON {
    proxy = { host = "127.0.0.1"; port = proxyPort; };
    ollama = { host = "127.0.0.1"; port = ollamaPort; };
    dashboard = { host = "127.0.0.1"; port = dashboardPort; };
    limits = {
      maxLogs = 500;
      requestBodyMaxChars = 50000;
      toolOutputMaxChars = 4000;
      streamTimeoutMs = 1800000; # 30 min — a 131K-context turn on a 27B model is slow
    };
  });

  ollama-flow-visualizer = pkgs.buildNpmPackage {
    pname = "ollama-flow-visualizer";
    version = "1.0.0-unstable-2026-05-07";

    src = pkgs.fetchFromGitHub {
      owner = "Paxy";
      repo = "Ollama-flow-visualizer";
      rev = "cede98c220021c821cf9bf41e1305a0966611ece";
      hash = "sha256-++SLqptV3cQbUuh6g3EyxeRoPuJP+okAuqLBUQIpqWQ=";
    };
    npmDepsHash = "sha256-0RCAsIHELlqwL0SLRczp4nkLV2Ofz3mfAf9utD8fhRE=";

    dontNpmBuild = true; # plain node server, no build step

    # The dashboard listener ignores its own `dashboard.host` setting and binds
    # 0.0.0.0 unconditionally. The firewall already blocks it, but honouring the
    # setting keeps the bind loopback-only too.
    postPatch = ''
      substituteInPlace server.js \
        --replace-fail "tryListenWeb('0.0.0.0', WEB_PORT)" \
                       "tryListenWeb(config.dashboard?.host || '0.0.0.0', WEB_PORT)"
    '';

    nativeBuildInputs = [ pkgs.makeWrapper ];

    installPhase = ''
      runHook preInstall
      mkdir -p $out/share/ollama-flow-visualizer
      cp -r server.js public node_modules $out/share/ollama-flow-visualizer/
      cp ${configFile} $out/share/ollama-flow-visualizer/config.json
      makeWrapper ${lib.getExe pkgs.nodejs} $out/bin/ollama-flow-visualizer \
        --add-flags $out/share/ollama-flow-visualizer/server.js
      runHook postInstall
    '';

    meta = {
      description = "Transparent Ollama proxy with a live request/response dashboard";
      homepage = "https://github.com/Paxy/Ollama-flow-visualizer";
      license = lib.licenses.mit;
      mainProgram = "ollama-flow-visualizer";
    };
  };
in
{
  systemd.services.ollama-flow-visualizer = {
    description = "Ollama Flow Visualizer — proxy + live prompt/response dashboard";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" "ollama.service" ];

    serviceConfig = {
      ExecStart = lib.getExe ollama-flow-visualizer;
      Restart = "on-failure";
      RestartSec = 5;

      DynamicUser = true;
      # No state on disk and no need for the model store — nothing to allow back in.
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      PrivateDevices = true;
      NoNewPrivileges = true;
      RestrictAddressFamilies = [ "AF_INET" "AF_INET6" ];
      RestrictNamespaces = true;
      LockPersonality = true;
      SystemCallFilter = [ "@system-service" ];
      # MemoryDenyWriteExecute is left off on purpose: V8's JIT needs W+X pages.
    };
  };
}
