#!/usr/bin/env bash

# Exit on error, undefined variable, and error in pipes
set -euo pipefail

# Check if any arguments were provided
if [ $# -eq 0 ]; then
    echo "Usage: $(basename "${0}") package1 package2 ..." >&2
    exit 1
fi

# Get current stable nixpkgs channel using shared norm command
STABLE_NIXPKGS=$(norm 2>/dev/null || echo "nixos-unstable")

# Build the command string starting with 'nix shell'
cmd="nom shell --impure"

# Loop through all arguments and prefix with nixpkgs#
for pkg in "$@"; do
    cmd+=" github:nixos/nixpkgs/${STABLE_NIXPKGS}#${pkg}"
done

export NIXPKGS_ALLOW_UNFREE=1
exec ${cmd} --command "${NOSH_SHELL}"
