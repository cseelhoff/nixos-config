#!/bin/sh
set -eu

nixos-rebuild switch --flake ".#$(hostname)"
