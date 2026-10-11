#!/bin/sh
set -eu

input=$(
  jq -r '.nodes.root.inputs | keys[]' flake.lock |
    fzf --height=40% --layout=reverse --border --prompt='Flake input to update: '
) || exit 0

nix flake update "$input"
