{ config, lib, pkgs, qwen3-tts, ... }:

# Qwen3-TTS — self-hosted speech for Marinara Engine and the Android engine (~/qwen3-tts-android).
#
# The server process starts at boot but is cheap: it never imports torch. The GPU worker loads the model on the first
# request (about 6 s) and is killed after `idleTimeoutSeconds` without requests, which returns all VRAM. Talking videos
# (LongCat, ~/LongCat-Video) need ~30 of the card's 32 GB, so Marinara also calls POST /unload before starting one.
#
# Reachable on the tailnet only: it binds this machine's Tailscale IPv4 and the firewall opens the port on tailscale0
# alone. Any device owned by the same Tailscale user is trusted (no token needed).
#
# First boot downloads several GB of wheels (`journalctl -u qwen3-tts-env -f`). Weights are cached in
# /var/lib/qwen3-tts/hf; pre-download them as described in the project README to avoid a slow first request.
#
# Marinara: Connections > Text to Speech > Source "Qwen3-TTS", address http://<tailscale-ip>:8880 (leave the key empty).

{
  imports = [ qwen3-tts.nixosModules.default ];

  services.qwen3-tts = {
    enable = true;
    idleTimeoutSeconds = 600;
  };

  # Quality over first-audio latency: the server's defaults cut a line after 48 characters (then up to 300) so streaming
  # starts quickly, but every cut is a separate generation with its own prosody. 600 keeps a whole spoken line in one piece.
  systemd.services.qwen3-tts.environment = {
    QWEN_TTS_FIRST_SEGMENT_MAX_CHARS = "600";
    QWEN_TTS_SEGMENT_MAX_CHARS = "600";
  };
}
