#!/usr/bin/env bash
# Fetch the latest Nicholasvoador/DLSS5-Swapper-Linux-Support release and
# update version + sha256 in pkgs/dlss5-swapper.nix from SHA256SUMS.txt.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
pkg_file="$repo_root/pkgs/dlss5-swapper.nix"
upstream="Nicholasvoador/DLSS5-Swapper-Linux-Support"

release_json="$(curl -fsSL "https://api.github.com/repos/${upstream}/releases/latest")"
tag="$(printf '%s\n' "$release_json" | jq -r '.tag_name')"
version="${tag#v}"
asset="DLSS5-Swapper-Linux-${version}-x86_64.AppImage"

sums="$(curl -fsSL "https://github.com/${upstream}/releases/download/${tag}/SHA256SUMS.txt")"
sha256="$(
  printf '%s\n' "$sums" |
    awk -v file="$asset" '$2 == file || $2 == ("*" file) { print $1; exit }'
)"

if [[ -z "$version" || "$version" == "null" || ! "$sha256" =~ ^[0-9a-f]{64}$ ]]; then
  echo "error: failed to resolve version ($version) or sha256 ($sha256) for $asset" >&2
  exit 1
fi

current_version="$(sed -n 's/.*version = "\([^"]*\)";.*/\1/p' "$pkg_file" | head -n1)"
if [[ "$current_version" == "$version" ]]; then
  echo "dlss5-swapper is already at $version ($sha256)"
  exit 0
fi

sed -i -E \
  -e "s|(version = \")[^\"]+(\";)|\1${version}\2|" \
  -e "s|(sha256 = \")[0-9a-f]{64}(\";)|\1${sha256}\2|" \
  "$pkg_file"

echo "Updated pkgs/dlss5-swapper.nix: $current_version -> $version"
echo "  asset:  $asset"
echo "  sha256: $sha256"
echo "Run 'sudo nixos-rebuild switch --flake .#x870' to apply."
