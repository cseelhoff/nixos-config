{ config, lib, pkgs, nixpkgs-ollama, ... }:

# Ollama — local LLM runtime that serves the dnd-ai GM reasoning brain
# (~/dnd-ai, ADR 0032). Runs Gemma 4 on the RTX 5090. The `ollama-cuda` package
# (below) carries its own CUDA stack, but still needs the NVIDIA kernel driver
# from modules/nvidia.nix, so this module is only valid on a host that also
# imports that one.
#
# Loopback only (default 127.0.0.1:11434): the brain and Ollama are co-located,
# and the model store is not a LAN service.
#
# After the first `nixos-rebuild switch` that includes this module, pull the
# model once as your user (~20 GB, lands in /var/lib/ollama):
#   ollama pull hf.co/unsloth/gemma-4-31B-it-GGUF:UD-Q4_K_XL
# The LangGraph app then reaches it at http://localhost:11434.
#
# NOTE: Ollama is the CUDA-accelerated `ollama-cuda` from a dedicated pinned
# nixpkgs (flake input `nixpkgs-ollama`, see flake.nix), NOT the system's stable
# nixpkgs — stable's 0.21.1 bundles a llama.cpp that can't load gemma4 GGUFs that
# carry a vision projector ("unknown model architecture: 'gemma4'"). The first
# build compiles CUDA Ollama from source (unfree CUDA isn't in the binary cache)
# — expect a long initial rebuild.

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

    # CUDA build from the pinned rev (>=0.30, gemma4-aware llama.cpp). Setting
    # `package` directly is the module's preferred idiom; `acceleration = "cuda"`
    # would instead default the package to the STABLE pkgs.ollama-cuda (0.21.1),
    # defeating the pin.
    package = pkgs-ollama.ollama-cuda;
    # host + port default to 127.0.0.1:11434 — left at the default on purpose.

    environmentVariables = {
      # Flash Attention — the standard NVIDIA win: faster attention + a smaller
      # KV cache, which frees VRAM headroom so all model layers stay on the GPU.
      OLLAMA_FLASH_ATTENTION = "1";

      # Keep Gemma resident instead of unloading after 5 min idle. Pins the model
      # in VRAM (reserving it for Ollama's own use) and skips the ~3.5s reload on
      # the first turn of each session. Costs permanent VRAM while the service runs.
      OLLAMA_KEEP_ALIVE = "-1";

      # Quantize the KV cache to q8_0 (requires flash attention, above). gemma4's
      # hybrid sliding-window attention already makes context cheap; q8_0 roughly
      # halves the per-token KV cost on top of that, so the full 131K window
      # (dnd-ai settings.py LOCAL_NUM_CTX) stays 100% on the GPU. Measured 2026-06-28
      # as effectively lossless on retrieval, ~7% slower per token than f16.
      OLLAMA_KV_CACHE_TYPE = "q8_0";
    };
  };
}
