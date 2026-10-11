# Grok Bot on NixOS

Checked 2026-09-09.

- Grok Bot is the desktop client for hosted bots, distinct from the Grok Build
  terminal agent. Official pages: <https://x.ai/bot>, <https://x.ai/build>.
- No `grok-bot` package was found in the current nixpkgs GitHub code search:
  <https://github.com/search?q=repo%3ANixOS%2Fnixpkgs+%22grok-bot%22&type=code>.
  This is not proof that no third-party flake exists.
- The official Bot page's Linux dropdown offers an x64 AppImage at
  <https://api2.cursor.sh/updates/download/stable/linux-x64/grok-bot-6f47c900083d6a0c>.
  An HTTP HEAD request returned a redirect to
  <https://downloads.cursor.com/grokbot/stable/c1e7d7a46549956d25f53e9c0b9f59666e03aa3a/linux/x64/Grok_Bot_0.47.0.AppImage>.
  The main Linux download button instead points to a Debian package.
- Nix's `appimage-run` takes a local AppImage path, not an HTTP URL; download
  first, then use `nix run nixpkgs#appimage-run -- /path/to/download.AppImage`.
  Verified against this host's installed `appimage-exec.sh` implementation
  (`realpath`, local-file checks, extraction, then `AppRun` execution).
- This host already installs `appimage-run` with an extra zstd library:
  [gaming module](../../modules/gaming.nix#L129-L135).

## Open questions / confidence

Official download format and URL verified. The application was not downloaded
or launched, so runtime compatibility with this host is not yet tested.
