{ config, lib, pkgs, nixpkgs-ollama, ... }:

# Ollama — local LLM runtime that serves the dnd-ai GM reasoning brain
# (~/dnd-ai, ADR 0032). Runs Qwen3.8 27B on the RTX 5090. The `ollama-cuda` package
# (below) carries its own CUDA stack, but still needs the NVIDIA kernel driver
# from modules/nvidia.nix, so this module is only valid on a host that also
# imports that one.
#
# Loopback only (default 127.0.0.1:11434): the brain and Ollama are co-located,
# and the model store is not a LAN service.
#
# After the first `nixos-rebuild switch` that includes this module, build the
# model once as your user (~22 GB, lands in /var/lib/ollama). It is imported from a
# local GGUF rather than pulled — the abliterated build is what lets one model serve
# both the GM and the Narrator (ADR 0032 Clarification 2026-08-19):
#   ollama create qwen35-abliterated:27b -f ~/dnd-ai/Modelfile.qwen35-abliterated
#   ollama show qwen35-abliterated:27b   # must list the `tools` capability
# The LangGraph app then reaches it at http://localhost:11434.
#
# NOTE: Ollama is the CUDA-accelerated `ollama-cuda` from a dedicated pinned
# nixpkgs (flake input `nixpkgs-ollama`, see flake.nix), NOT the system's stable
# nixpkgs. The pin exists because a too-old bundled llama.cpp simply cannot load a
# newer model architecture ("unknown model architecture: '<arch>'") — first hit on
# gemma4 GGUFs under stable's 0.21.1, and the same constraint now binds on `qwen35`
# (Qwen3.8's hybrid attention/SSM arch), which needs >=0.30. The first build compiles
# CUDA Ollama from source (unfree CUDA isn't in the binary cache) — expect a long
# initial rebuild.

let
  # Fresh pkgs set from the pinned rev. `ollama-cuda` is the prebuilt CUDA variant
  # (its own `acceleration = "cuda"` enables CUDA internally), so this set does
  # NOT need nvidia.nix's system-wide nixpkgs.config.cudaSupport — only allowUnfree.
  pkgs-ollama = import nixpkgs-ollama {
    inherit (pkgs.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  };
in
{
  services.ollama = {
    enable = true;

    # CUDA build from the pinned rev (>=0.30, `qwen35`-aware llama.cpp). Setting
    # `package` directly is the module's preferred idiom; `acceleration = "cuda"`
    # would instead default the package to the STABLE pkgs.ollama-cuda (0.21.1),
    # defeating the pin.
    package = pkgs-ollama.ollama-cuda;
    # host + port default to 127.0.0.1:11434 — left at the default on purpose.

    environmentVariables = {
      # Flash Attention — the standard NVIDIA win: faster attention + a smaller
      # KV cache, which frees VRAM headroom so all model layers stay on the GPU.
      OLLAMA_FLASH_ATTENTION = "1";

      # Keep the model resident instead of unloading after 5 min idle. Pins it
      # in VRAM (reserving it for Ollama's own use) and skips the ~3.5s reload on
      # the first turn of each session. Costs permanent VRAM while the service runs.
      OLLAMA_KEEP_ALIVE = "-1";

      # Quantize the KV cache to q8_0 (requires flash attention, above). qwen35 is a
      # hybrid attention/SSM model — only every 4th layer is full attention — which
      # already makes context cheap; q8_0 roughly halves the per-token KV cost on top
      # of that, so the full 131K window (dnd-ai settings.py LOCAL_NUM_CTX) stays 100%
      # on the GPU: measured 2026-08-19 at 26 GiB resident of the card's 32 GiB.
      # Measured 2026-06-28 as effectively lossless on retrieval, ~7% slower than f16.
      OLLAMA_KV_CACHE_TYPE = "q8_0";
    };
  };
}
