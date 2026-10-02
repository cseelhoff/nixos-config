{ config, lib, pkgs, ... }:

# Tailscale: private WireGuard mesh to my other devices.
#
# Main consumer: ~/copilot-remote-voice (talk to Copilot from my phone).
# That server binds 127.0.0.1 only; `tailscale serve` gives it a private,
# tailnet-only HTTPS URL (https://x870.<tailnet>.ts.net) — HTTPS is
# required for mobile browsers to allow the microphone. Never use
# `tailscale funnel` for it (that would make it public).
#
# One-time, after the first rebuild:
#   sudo tailscale up --operator=caleb   # log in; operator lets caleb run
#                                        # `tailscale serve` without sudo
# Then enable MagicDNS + HTTPS certificates in the admin console (DNS page).
#
# Per use (as caleb):
#   tailscale serve --bg 8765    # proxy https://x870.<tailnet>.ts.net → 127.0.0.1:8765
#   tailscale serve status
#   tailscale serve reset        # stop exposing it

{
  services.tailscale = {
    enable = true;
    # UDP 41641 for direct peer-to-peer connections (otherwise traffic is
    # relayed via DERP — works, but adds latency to voice round-trips).
    openFirewall = true;
  };
}
