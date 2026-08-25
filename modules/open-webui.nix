{ pkgs, ... }:

# Open WebUI — local web front end for the models served by modules/ollama.nix,
# so this module is only useful on a host that also imports that one.
#
# Loopback only (127.0.0.1:11436), matching Ollama's own posture: a personal
# front end, not a LAN service. `openFirewall` stays off deliberately — to reach
# it from another machine, forward the port over SSH rather than opening it.
#
# The port is NOT the module default of 8080: that is mitmproxy's default listen
# port, and a `mitmdump` capture on this box silently took it first, leaving the
# service in a bind-failure crash loop. 11436 sits with the rest of the local LLM
# stack instead — Ollama 11434, grok-bridge 11435.
#
# State (accounts, chat history, settings) lands in /var/lib/open-webui as
# SQLite. The first visit asks you to create an account, and the first account
# created becomes the admin; it is local to this machine, not an x.ai or
# OpenAI login.
#
# Deliberately from STABLE nixpkgs, not the pinned `nixpkgs-ollama` input. That
# pin exists solely because Ollama's bundled llama.cpp must recognise newer model
# architectures — a constraint that has nothing to do with the web UI, so
# tracking it here would only add churn.
#
# ...but it IS built from a pkgs set with CUDA switched off. modules/nvidia.nix
# sets nixpkgs.config.cudaSupport system-wide, which rebuilds every CUDA-capable
# dependency from source — and Open WebUI drags in a large one (torch,
# ctranslate2, opencv, ffmpeg-full via its optional local speech-to-text).
# Measured 2026-08-21: with cudaSupport inherited it was 60 source derivations
# and ~1.9 GB of fetches, including magma and nccl; without it, everything comes
# from the binary cache. Nothing here runs on the GPU — inference happens in the
# Ollama process — so the CUDA build bought nothing.

let
  # Same nixpkgs revision as the rest of the system, only the config differs.
  pkgs-nocuda = import pkgs.path {
    inherit (pkgs.stdenv.hostPlatform) system;
    config.allowUnfree = true; # cudaSupport intentionally absent
  };
in
{
  services.open-webui = {
    enable = true;
    package = pkgs-nocuda.open-webui;
    port = 11436; # not 8080; see the header note on mitmproxy
    # host is left at its default (127.0.0.1).

    environment = {
      # Defining this attrset REPLACES the module's default rather than merging
      # with it, and the default is where these three opt-outs live — so they are
      # restated here instead of being silently dropped.
      SCARF_NO_ANALYTICS = "True";
      DO_NOT_TRACK = "True";
      ANONYMIZED_TELEMETRY = "False";

      # Deliberately the Flow Visualizer proxy (modules/ollama-flow-visualizer.nix),
      # not Ollama's own 11434 — that is what puts this UI's prompts and responses
      # on the dashboard at http://127.0.0.1:11438. The proxy is transparent, so
      # revert to "http://127.0.0.1:11434" to take it out of the path.
      OLLAMA_BASE_URL = "http://127.0.0.1:11437";

      # The point of this box is local models; without this the UI probes
      # api.openai.com on every model list and shows a spurious connection error.
      ENABLE_OPENAI_API = "False";
    };
  };
}
